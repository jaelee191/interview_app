#!/usr/bin/env ruby
require_relative 'config/environment'

cl = CoverLetter.find(63)

puts "=" * 60
puts "Cover Letter 63 수정"
puts "=" * 60

# 1. {text: "..."} 형식 제거
if cl.analysis_result && cl.analysis_result.start_with?('{text: "')
  puts "❌ 잘못된 형식 발견: JSON 문자열로 래핑됨"
  
  # 실제 텍스트 추출
  text = cl.analysis_result
  text = text.sub(/^\{text:\s*"/, '')
  text = text.sub(/"\}$/, '')
  
  # 이스케이프 처리
  text = text.gsub('\\n', "\n")
  text = text.gsub('\\"', '"')
  text = text.gsub('\\\\', '\\')
  
  puts "✅ 텍스트 추출 완료"
  puts "  원본 길이: #{cl.analysis_result.length}"
  puts "  추출 길이: #{text.length}"
  
  # 2. 프롬프트 명령어 제거
  original_text = text.dup
  
  # [1문단], [2문단] 등 제거
  text = text.gsub(/\[\d+문단\]\s*/m, '')
  
  # [소제목] 같은 패턴 제거
  text = text.gsub(/\[([^\]]+)\]\s*(?=\n)/m, '\1')
  
  if original_text != text
    puts "✅ 프롬프트 명령어 제거 완료"
  end
  
  # 3. 섹션 확인
  sections = text.scan(/^##\s+\d+\./)
  puts "\n발견된 섹션: #{sections.length}개"
  
  # analysis_result 업데이트
  cl.update!(analysis_result: text)
  puts "\n✅ analysis_result 업데이트 완료"
  
  # 4. 파싱하여 JSON 생성
  service = AdvancedCoverLetterService.new
  parsed = service.parse_analysis_to_json(text)
  
  if parsed
    # 5. 각 섹션의 문단 구분 개선
    parsed['sections'].each do |section|
      section_num = section['number'].to_i
      
      # 섹션 1과 5의 문단 구분
      if (section_num == 1 || section_num == 5) && section['content'].present?
        content = section['content']
        
        # 이미 문단 구분이 있는지 확인
        if content.scan(/\n\n/).count < 2
          # 문장을 문단으로 나누기
          sentences = content.split(/(?<=[.!?])\s+/)
          paragraphs = []
          current_paragraph = []
          current_length = 0
          
          sentences.each do |sentence|
            current_paragraph << sentence
            current_length += sentence.length
            
            # 300자 이상이거나 3-4문장이 모이면 문단 구분
            if current_length > 300 || current_paragraph.length >= 3
              paragraphs << current_paragraph.join(' ')
              current_paragraph = []
              current_length = 0
            end
          end
          
          # 남은 문장 처리
          paragraphs << current_paragraph.join(' ') unless current_paragraph.empty?
          
          # 문단 사이에 이중 줄바꿈 추가
          section['content'] = paragraphs.join("\n\n")
          
          puts "섹션 #{section_num} 문단 구분: #{paragraphs.length}개"
        end
      end
    end
    
    cl.update!(advanced_analysis_json: parsed)
    puts "\n✅ JSON 파싱 성공!"
    puts "파싱된 섹션:"
    parsed['sections'].each do |section|
      items_count = section['items'].is_a?(Array) ? section['items'].length : 0
      puts "  - 섹션 #{section['number']}: #{section['title']} (items: #{items_count})"
    end
  else
    puts "\n❌ JSON 파싱 실패"
  end
else
  puts "✅ 정상적인 형식"
  
  # 파싱만 시도
  if cl.advanced_analysis_json.blank?
    service = AdvancedCoverLetterService.new
    parsed = service.parse_analysis_to_json(cl.analysis_result)
    
    if parsed
      cl.update!(advanced_analysis_json: parsed)
      puts "✅ JSON 파싱 완료"
    end
  end
end

puts "\n" + "=" * 60
puts "완료!"