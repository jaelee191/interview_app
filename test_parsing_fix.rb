#!/usr/bin/env ruby
require_relative 'config/environment'

# 저장된 분석 결과 읽기
text = File.read('/tmp/mmmd_analysis_text.txt')

# 수정된 파싱 로직 테스트
service = AdvancedCoverLetterService.new

# 강점 섹션 추출
strengths_section = text[/## 2\. 잘 쓴 부분.*?(?=## 3\.|$)/m]
puts "=== 강점 섹션 파싱 테스트 ==="
puts "강점 섹션 길이: #{strengths_section.length}자"

# 파싱 실행
items = service.send(:parse_numbered_items, strengths_section)

puts "\n파싱 결과: #{items.length}개 항목"
puts "=" * 80

items.each_with_index do |item, i|
  puts "\n### 항목 #{i+1}: #{item[:title]}"
  puts "내용 길이: #{item[:content].length}자"
  
  # 내용에 3개 문단이 모두 포함되었는지 확인
  paragraphs = item[:content].scan(/\[\d문단/)
  puts "포함된 문단: #{paragraphs.join(', ')}"
  
  # 첫 200자와 마지막 200자 출력
  if item[:content].length > 400
    puts "\n첫 부분: #{item[:content][0..200]}..."
    puts "\n끝 부분: ...#{item[:content][-200..-1]}"
  else
    puts "\n전체 내용: #{item[:content]}"
  end
  puts "-" * 80
end

# JSON 재생성 테스트
puts "\n=== JSON 재생성 테스트 ==="
result = service.analyze_cover_letter_parallel(File.read('/Users/macmac/Documents/DV/interview/interview_app/test_mmmd_cover_letter.rb').split('CONTENT')[1])

# JSON 저장
File.write('/tmp/mmmd_analysis_json_fixed.json', JSON.pretty_generate(result[:json]))
puts "✅ 수정된 JSON 저장: /tmp/mmmd_analysis_json_fixed.json"

# 수정된 JSON에서 첫 번째 강점 항목 확인
first_strength = result[:json][:sections][1][:items][0]
puts "\n첫 번째 강점 항목:"
puts "제목: #{first_strength[:title]}"
puts "내용 길이: #{first_strength[:content].length}자"
puts "내용에 포함된 문단: #{first_strength[:content].scan(/\[\d문단/).join(', ')}"