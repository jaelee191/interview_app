require 'open3'
require 'json'
require 'tempfile'

class PdfExtractorService
  PYTHON_SCRIPT_PATH = Rails.root.join('lib', 'python', 'pdf_extractor_enhanced.py').to_s
  
  class << self
    # PDF 파일에서 자소서 추출
    def extract_cover_letter(pdf_path_or_content, is_file_path: true)
      return { error: 'No input provided' } unless pdf_path_or_content.present?
      
      if is_file_path
        # 파일 경로로 직접 처리
        extract_from_file(pdf_path_or_content)
      else
        # 바이너리 콘텐츠를 임시 파일로 저장 후 처리
        extract_from_content(pdf_path_or_content)
      end
    rescue => e
      Rails.logger.error "PDF extraction failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { error: "PDF 추출 실패: #{e.message}" }
    end
    
    # 사용 가능한 라이브러리 확인
    def check_libraries
      output, error, status = Open3.capture3('python3', PYTHON_SCRIPT_PATH, 'info')
      
      if status.success?
        JSON.parse(output).deep_symbolize_keys
      else
        { error: "Python 확인 실패: #{error}" }
      end
    rescue => e
      { error: "라이브러리 확인 실패: #{e.message}" }
    end
    
    # Python 라이브러리 설치
    def install_libraries
      requirements_path = Rails.root.join('lib', 'python', 'requirements.txt')
      
      # pip install 실행
      output, error, status = Open3.capture3(
        'pip3', 'install', '-r', requirements_path.to_s
      )
      
      if status.success?
        { success: true, message: '라이브러리 설치 완료', output: output }
      else
        { success: false, error: "설치 실패: #{error}" }
      end
    rescue => e
      { success: false, error: "설치 오류: #{e.message}" }
    end
    
    private
    
    def extract_from_file(pdf_path)
      # 파일 존재 확인
      unless File.exist?(pdf_path)
        return { error: "파일을 찾을 수 없습니다: #{pdf_path}" }
      end
      
      # Python 스크립트 실행 (venv 사용)
      venv_python = Rails.root.join('venv', 'bin', 'python').to_s
      python_cmd = File.exist?(venv_python) ? venv_python : 'python3'
      
      output, error, status = Open3.capture3(
        python_cmd, PYTHON_SCRIPT_PATH, 'extract', pdf_path
      )
      
      if status.success?
        result = JSON.parse(output).deep_symbolize_keys
        
        # 추가 처리
        if result[:has_cover_letter]
          result[:cover_letter_sections] = enhance_sections(result[:cover_letter_sections])
          result[:extraction_quality] = assess_quality(result)
        end
        
        result
      else
        Rails.logger.error "Python extraction error: #{error}"
        
        # 폴백: Ruby 기반 추출 시도
        fallback_extract(pdf_path)
      end
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing failed: #{e.message}"
      Rails.logger.error "Output was: #{output}"
      
      # 폴백 사용
      fallback_extract(pdf_path)
    end
    
    def extract_from_content(pdf_content)
      # 임시 파일 생성
      temp_file = Tempfile.new(['pdf_extract', '.pdf'], binmode: true)
      
      begin
        # 콘텐츠 쓰기
        temp_file.write(pdf_content)
        temp_file.flush
        
        # 파일 경로로 추출
        extract_from_file(temp_file.path)
      ensure
        # 임시 파일 정리
        temp_file.close
        temp_file.unlink
      end
    end
    
    def fallback_extract(pdf_path)
      Rails.logger.info "Using Ruby fallback extraction"
      
      # 기존 Ruby 기반 추출 로직 사용
      begin
        reader = PDF::Reader.new(pdf_path)
        pages_text = reader.pages.map(&:text)
        
        # 간단한 자소서 감지
        cover_letter_pages = []
        cover_letter_text = []
        
        pages_text.each_with_index do |text, index|
          if text =~ /자기소개서|지원동기|성장과정|cover letter/i
            cover_letter_pages << index + 1
            cover_letter_text << text
          end
        end
        
        {
          total_pages: pages_text.length,
          has_cover_letter: cover_letter_pages.any?,
          cover_letter_pages: cover_letter_pages,
          cover_letter_text: cover_letter_text.join("\n\n"),
          extraction_method: 'ruby_fallback',
          confidence: 60
        }
      rescue => e
        { error: "Ruby 추출도 실패: #{e.message}" }
      end
    end
    
    def enhance_sections(sections)
      return [] unless sections.present?
      
      sections.map do |section|
        # 섹션 제목 정규화
        normalized_title = normalize_section_title(section[:title])
        
        # 내용 요약 생성 (처음 200자)
        summary = section[:content].to_s[0..200].strip
        summary += '...' if section[:content].to_s.length > 200
        
        {
          title: section[:title],
          normalized_title: normalized_title,
          content: section[:content],
          summary: summary,
          word_count: section[:content].to_s.split.length
        }
      end
    end
    
    def normalize_section_title(title)
      return '' unless title.present?
      
      # 번호 제거
      normalized = title.gsub(/^\d+[\.\)]\s*/, '')
      normalized = normalized.gsub(/^Q\d+[\.:]\s*/i, '')
      
      # 공백 정규화
      normalized.strip.gsub(/\s+/, ' ')
    end
    
    def assess_quality(result)
      quality_score = 0
      
      # 신뢰도 기반
      quality_score += result[:confidence].to_f * 0.5
      
      # 섹션 개수 기반
      section_count = result[:cover_letter_sections]&.length || 0
      quality_score += [section_count * 10, 30].min
      
      # 텍스트 길이 기반
      text_length = result[:cover_letter_text]&.length || 0
      if text_length > 2000
        quality_score += 20
      elsif text_length > 1000
        quality_score += 10
      end
      
      {
        score: quality_score.round,
        rating: case quality_score
                when 80..100 then '우수'
                when 60..79 then '양호'
                when 40..59 then '보통'
                else '미흡'
                end,
        details: {
          confidence: result[:confidence],
          sections: section_count,
          text_length: text_length
        }
      }
    end
  end
end