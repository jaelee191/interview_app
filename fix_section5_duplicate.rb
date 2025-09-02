#!/usr/bin/env ruby
require_relative 'config/environment'

cl = CoverLetter.find(62)

puts "=" * 60
puts "Cover Letter 62 - 섹션 5 중복 제거"
puts "=" * 60

# analysis_result에서 다시 파싱
if cl.analysis_result.present?
  service = AdvancedCoverLetterService.new
  
  # 원본 텍스트에서 다시 파싱
  parsed = service.parse_analysis_to_json(cl.analysis_result)
  
  if parsed && parsed['sections'].present?
    puts "\n✅ 재파싱 성공"
    
    # 각 섹션 확인
    parsed['sections'].each do |section|
      puts "\n섹션 #{section['number']}: #{section['title']}"
      
      if section['content'].present?
        # 처음 100자 출력
        puts "  Content 처음 100자: #{section['content'][0..100]}..."
        puts "  Content 길이: #{section['content'].length}"
      end
      
      if section['items'].present? && section['items'].any?
        puts "  Items 개수: #{section['items'].length}"
        section['items'].each do |item|
          puts "    - #{item['type']} #{item['number']}: #{item['title']}"
        end
      end
    end
    
    # 섹션 5 확인
    section5 = parsed['sections'].find { |s| s['number'].to_i == 5 }
    if section5
      puts "\n" + "=" * 40
      puts "섹션 5 상세 확인:"
      
      # 섹션 1 내용이 포함되어 있는지 확인
      if section5['content'].include?('전반적으로 명확한 구조')
        puts "⚠️  섹션 1 내용이 포함되어 있음"
        
        # 실제 섹션 5 내용만 추출
        if section5['content'] =~ /(처음 취업을 준비할 때의 설렘과 불안.*)/m
          section5['content'] = $1
          puts "✅ 섹션 5 내용 수정 완료"
          puts "수정된 내용 처음 200자:"
          puts section5['content'][0..200]
        end
      else
        puts "✅ 섹션 5 내용 정상"
      end
    end
    
    # DB 업데이트
    cl.update!(advanced_analysis_json: parsed)
    puts "\n✅ 데이터베이스 업데이트 완료"
    
  else
    puts "❌ 파싱 실패"
  end
else
  puts "❌ analysis_result가 없습니다"
end