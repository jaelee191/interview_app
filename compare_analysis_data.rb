#!/usr/bin/env ruby
require_relative 'config/environment'

cover_letter_id = ARGV[0] || 61
cl = CoverLetter.find(cover_letter_id)

puts "=" * 80
puts "📊 Cover Letter #{cover_letter_id} - 분석 데이터 비교"
puts "=" * 80

# 1. 원본 분석 텍스트
puts "\n📝 [1] analysis_result (원본 분석 텍스트)"
puts "-" * 40
if cl.analysis_result
  puts "총 길이: #{cl.analysis_result.length} 문자"
  
  # 섹션별 텍스트 길이 확인
  sections = cl.analysis_result.split(/^##\s+\d+\./)
  puts "섹션 개수: #{sections.length - 1}" # 첫 번째는 빈 문자열
else
  puts "❌ analysis_result가 없음"
end

# 2. 파싱된 JSON 구조
puts "\n🔄 [2] advanced_analysis_json (파싱된 JSON)"
puts "-" * 40
if cl.advanced_analysis_json
  json_data = cl.advanced_analysis_json
  puts "파싱 시간: #{json_data['parsed_at']}" if json_data['parsed_at']
  
  if json_data['sections']
    puts "섹션 개수: #{json_data['sections'].length}"
    
    json_data['sections'].each do |section|
      puts "\n  📌 섹션 #{section['number']}: #{section['title']}"
      puts "     - content: #{section['content'].length} 문자"
      puts "     - items: #{section['items'].length}개"
      
      if section['items'].any? && section['number'].to_i == 2  # 강점 섹션 상세
        puts "\n     🎯 강점 항목 상세:"
        section['items'].each do |item|
          puts "       #{item['type']} #{item['number']}: #{item['title']}"
          puts "       → content: #{item['content'].length} 문자"
          puts "       → 첫 50자: #{item['content'][0..50]}..." if item['content'].length > 0
        end
      end
    end
  end
else
  puts "❌ advanced_analysis_json이 없음"
end

# 3. 데이터 일치성 검증
puts "\n✅ [3] 데이터 일치성 검증"
puts "-" * 40

if cl.analysis_result && cl.advanced_analysis_json
  # 강점 섹션 비교
  text_strengths = cl.analysis_result[/## 2\. 잘 쓴 부분.*?(?=## 3\.|\z)/m]
  json_strengths = cl.advanced_analysis_json['sections'].find { |s| s['number'] == '2' }
  
  if text_strengths && json_strengths
    # 텍스트에서 "### 강점" 개수 세기
    text_strength_count = text_strengths.scan(/### 강점 \d+:/).length
    json_strength_count = json_strengths['items'].length
    
    puts "강점 항목 개수:"
    puts "  - 원본 텍스트: #{text_strength_count}개"
    puts "  - 파싱된 JSON: #{json_strength_count}개"
    puts "  - 일치 여부: #{text_strength_count == json_strength_count ? '✅ 일치' : '❌ 불일치'}"
    
    # 각 강점의 제목 비교
    if json_strengths['items'].any?
      puts "\n강점 제목 비교:"
      json_strengths['items'].each do |item|
        pattern = /### 강점 #{item['number']}:\s*(.+?)$/
        if text_strengths =~ pattern
          text_title = $1.strip
          json_title = item['title'].strip
          match = text_title == json_title
          puts "  #{item['number']}. #{match ? '✅' : '❌'} #{json_title}"
          puts "     (원본: #{text_title})" unless match
        end
      end
    end
  end
else
  puts "비교할 데이터가 부족합니다."
end

puts "\n" + "=" * 80
puts "비교 완료"