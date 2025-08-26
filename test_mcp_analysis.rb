#!/usr/bin/env rails runner
# MCP 스냅샷 분석 테스트 스크립트

url = ARGV[0] || "https://www.saramin.co.kr/zf_user/jobs/relay/pop-view?rec_idx=51628653"

puts "🎯 MCP 스냅샷 분석 테스트 시작"
puts "URL: #{url}"
puts "-" * 50

service = McpJobAnalyzerService.new
result = service.analyze_with_snapshot(url)

if result[:success]
  puts "✅ 분석 성공!"
  puts "\n📊 기본 정보:"
  puts "- 회사명: #{result[:data][:basic_info][:company_name]}"
  puts "- 포지션: #{result[:data][:basic_info][:position]}"
  puts "- 위치: #{result[:data][:basic_info][:location]}"
  puts "- 마감일: #{result[:data][:basic_info][:deadline]}"
  
  puts "\n📋 요구사항:"
  puts "필수: #{result[:data][:requirements][:required].join(', ')}" if result[:data][:requirements][:required].any?
  puts "우대: #{result[:data][:requirements][:preferred].join(', ')}" if result[:data][:requirements][:preferred].any?
  
  puts "\n🎁 복지/혜택:"
  puts result[:data][:benefits].join(', ') if result[:data][:benefits].any?
  
  puts "\n📝 상세 분석:"
  puts result[:data][:analysis_result]
  
  puts "\n✅ 스냅샷 캡처: #{result[:data][:screenshot_captured]}"
  puts "✅ 분석 시간: #{result[:data][:analyzed_at]}"
else
  puts "❌ 분석 실패: #{result[:error]}"
end