#!/usr/bin/env ruby
require_relative 'config/environment'

def add_paragraph_breaks(content)
  # 문장을 더 자연스럽게 문단으로 나누기
  # 300-400자 정도씩, 또는 의미 단위로 구분
  
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
  paragraphs.join("\n\n")
end

# Cover Letter 62 처리
cl = CoverLetter.find(62)

puts "=" * 60
puts "Cover Letter 62 - 문단 간격 개선"
puts "=" * 60

if cl.advanced_analysis_json.present?
  json = cl.advanced_analysis_json.deep_dup
  updated = false
  
  json['sections'].each do |section|
    section_num = section['number'].to_i
    
    # 섹션 1과 5만 처리 (첫인상과 격려 메시지)
    if (section_num == 1 || section_num == 5) && section['content'].present?
      original = section['content']
      
      # 이미 문단 구분이 있는지 확인
      if original.scan(/\n\n/).count < 2
        # 문단 구분이 부족하면 추가
        new_content = add_paragraph_breaks(original)
        section['content'] = new_content
        updated = true
        
        puts "\n섹션 #{section_num}: #{section['title']}"
        puts "  원본 문단 수: #{original.scan(/\n\n/).count + 1}"
        puts "  수정 문단 수: #{new_content.scan(/\n\n/).count + 1}"
        puts "  원본 길이: #{original.length}"
        puts "  수정 길이: #{new_content.length}"
        
        puts "\n수정된 내용 (처음 500자):"
        puts new_content[0..500]
      else
        puts "\n섹션 #{section_num}: 이미 문단 구분됨"
      end
    end
  end
  
  if updated
    cl.update!(advanced_analysis_json: json)
    puts "\n✅ DB 업데이트 완료"
  else
    puts "\n변경 사항 없음"
  end
else
  puts "advanced_analysis_json이 없습니다"
end

# 모든 Cover Letter 처리 함수
def process_all_cover_letters
  CoverLetter.where.not(advanced_analysis_json: nil).find_each do |cl|
    json = cl.advanced_analysis_json.deep_dup
    updated = false
    
    json['sections'].each do |section|
      section_num = section['number'].to_i
      
      if (section_num == 1 || section_num == 5) && section['content'].present?
        original = section['content']
        
        if original.scan(/\n\n/).count < 2
          section['content'] = add_paragraph_breaks(original)
          updated = true
        end
      end
    end
    
    if updated
      cl.update!(advanced_analysis_json: json)
      puts "Cover Letter #{cl.id} 업데이트"
    end
  end
end

# 전체 처리하려면 아래 주석 해제
# process_all_cover_letters