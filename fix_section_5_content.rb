#!/usr/bin/env ruby
require_relative 'config/environment'

# 모든 Cover Letter의 섹션 5 content 정리
def clean_section_5_content
  CoverLetter.where.not(advanced_analysis_json: nil).find_each do |cl|
    puts "\n" + "=" * 60
    puts "Cover Letter #{cl.id} 처리"
    
    if cl.advanced_analysis_json.present? && cl.advanced_analysis_json['sections'].present?
      json = cl.advanced_analysis_json.deep_dup
      updated = false
      
      json['sections'].each do |section|
        if section['number'].to_i == 5 && section['content'].present?
          original_content = section['content']
          
          # 불필요한 텍스트 패턴들 제거
          cleaned_content = original_content.dup
          
          # 여러 패턴으로 끝부분 정리
          patterns_to_remove = [
            /\s+items:\s*\[\].*/m,
            /\s+analyzed_at:.*/m,
            /\.\s+[가-힣]+님은\s+실무\s+경험과.*/m,  # 중복된 요약 제거
            /종합적으로\s+볼\s+때.*/m  # 중복된 평가 제거
          ]
          
          patterns_to_remove.each do |pattern|
            if cleaned_content =~ pattern
              cleaned_content = cleaned_content.sub(pattern, '')
              puts "  ✅ 패턴 제거: #{pattern.inspect[0..50]}..."
            end
          end
          
          # 마지막 완전한 문장에서 끊기
          # 마침표, 느낌표, 물음표로 끝나는 마지막 문장 찾기
          if cleaned_content =~ /(.+[.!?])[^.!?]*$/m
            cleaned_content = $1
          end
          
          # 앞뒤 공백 제거
          cleaned_content = cleaned_content.strip
          
          if original_content != cleaned_content
            section['content'] = cleaned_content
            updated = true
            
            puts "  원본 길이: #{original_content.length}"
            puts "  수정 길이: #{cleaned_content.length}"
            puts "  제거된 길이: #{original_content.length - cleaned_content.length}"
            
            # 마지막 100자 비교
            puts "\n  원본 마지막 100자:"
            puts "  #{original_content[-100..-1]}" if original_content.length > 100
            puts "\n  수정 마지막 100자:"
            puts "  #{cleaned_content[-100..-1]}" if cleaned_content.length > 100
          else
            puts "  ✅ 이미 깨끗함"
          end
        end
      end
      
      if updated
        cl.update!(advanced_analysis_json: json)
        puts "  ✅ 데이터베이스 업데이트 완료"
      end
    else
      puts "  ⏭️  advanced_analysis_json 없음"
    end
  end
  
  puts "\n" + "=" * 60
  puts "모든 Cover Letter 처리 완료"
end

# 특정 Cover Letter만 처리
def clean_specific_cover_letter(id)
  cl = CoverLetter.find(id)
  
  puts "=" * 60
  puts "Cover Letter #{cl.id} 개별 처리"
  puts "=" * 60
  
  if cl.advanced_analysis_json.present? && cl.advanced_analysis_json['sections'].present?
    json = cl.advanced_analysis_json.deep_dup
    
    json['sections'].each do |section|
      if section['number'].to_i == 5
        puts "\n섹션 5: #{section['title']}"
        puts "-" * 40
        
        if section['content'].present?
          original = section['content']
          
          # 정리
          cleaned = original.dup
          cleaned = cleaned.sub(/\s+items:\s*\[\].*/m, '')
          cleaned = cleaned.sub(/\s+analyzed_at:.*/m, '')
          cleaned = cleaned.sub(/\.\s+[가-힣]+님은\s+실무\s+경험과.*/m, '')
          cleaned = cleaned.sub(/종합적으로\s+볼\s+때.*/m, '')
          
          # 마지막 완전한 문장까지만
          if cleaned =~ /(.+[.!?])[^.!?]*$/m
            cleaned = $1
          end
          
          cleaned = cleaned.strip
          
          section['content'] = cleaned
          
          puts "원본 길이: #{original.length}"
          puts "수정 길이: #{cleaned.length}"
          puts "\n마지막 200자 (수정 후):"
          puts cleaned[-200..-1] if cleaned.length > 200
        end
        
        # items 배열 확인 및 제거
        if section['items'].is_a?(Array) && section['items'].empty?
          section.delete('items')
          puts "\n✅ 빈 items 배열 제거"
        end
      end
    end
    
    cl.update!(advanced_analysis_json: json)
    puts "\n✅ 업데이트 완료"
  end
end

# 실행
if ARGV[0]
  # 특정 ID 처리
  clean_specific_cover_letter(ARGV[0].to_i)
else
  # 전체 처리
  clean_section_5_content
end