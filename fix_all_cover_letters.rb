#!/usr/bin/env ruby
require_relative 'config/environment'

def fix_cover_letter(cl)
  return unless cl.analysis_result.present?
  
  # 1. {text: "..."} 형식 제거
  if cl.analysis_result.start_with?('{text: "')
    puts "  ❌ ID #{cl.id}: {text: 래핑 발견"
    
    # 실제 텍스트 추출
    text = cl.analysis_result
    text = text.sub(/^\{text:\s*"/, '')
    text = text.sub(/"\s*,?\s*json:.*\}$/m, '')  # json 부분도 제거
    text = text.sub(/"\}$/, '')  # 끝의 "} 제거
    
    # 이스케이프 처리
    text = text.gsub('\\n', "\n")
    text = text.gsub('\\"', '"')
    text = text.gsub('\\\\', '\\')
    
    cl.analysis_result = text
  end
  
  # 2. 프롬프트 명령어 제거
  if cl.analysis_result.include?('[1문단') || cl.analysis_result.include?('[2문단')
    puts "  ⚠️  ID #{cl.id}: 프롬프트 명령어 제거"
    
    # [N문단] 패턴 제거
    cl.analysis_result = cl.analysis_result.gsub(/\[\d+문단\]\s*/m, '')
    
    # [소제목] 같은 패턴도 제거
    cl.analysis_result = cl.analysis_result.gsub(/\[([^\]]+)\]\s*(?=\n)/m) do
      match = $1
      # 해시태그는 유지
      if match.start_with?('#')
        "[#{match}]"
      else
        match
      end
    end
  end
  
  # 3. JSON 파싱
  if cl.advanced_analysis_json.blank? && cl.analysis_result.present?
    service = AdvancedCoverLetterService.new
    parsed = service.parse_analysis_to_json(cl.analysis_result)
    
    if parsed
      # 섹션 1과 5의 문단 구분 개선
      parsed['sections'].each do |section|
        section_num = section['number'].to_i
        
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
          end
        end
      end
      
      cl.advanced_analysis_json = parsed
      puts "  ✅ ID #{cl.id}: JSON 파싱 완료"
    end
  end
  
  # 변경사항 저장
  if cl.changed?
    cl.save!
    puts "  💾 ID #{cl.id}: 저장 완료"
    true
  else
    false
  end
end

puts "=" * 60
puts "모든 Cover Letter 수정"
puts "=" * 60

fixed_count = 0
total_count = 0

CoverLetter.where.not(analysis_result: nil).find_each do |cl|
  total_count += 1
  if fix_cover_letter(cl)
    fixed_count += 1
  end
end

puts "\n" + "=" * 60
puts "완료!"
puts "전체: #{total_count}개"
puts "수정: #{fixed_count}개"