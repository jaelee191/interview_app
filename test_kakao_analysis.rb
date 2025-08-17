#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🚀 카카오 강화 기업 분석 테스트 시작..."
puts "=" * 50

# EnhancedCompanyAnalyzerService 테스트
service = EnhancedCompanyAnalyzerService.new("카카오")

puts "\n📊 분석 시작: #{Time.now}"
result = service.perform_enhanced_analysis

puts "\n✅ 분석 완료: #{Time.now}"
puts "=" * 50

# 결과 출력
puts "\n📌 Executive Summary:"
puts result[:executive_summary][0..500] if result[:executive_summary]

puts "\n📌 웹 크롤링 데이터:"
if result[:scraped_data]
  puts "- 채용공고 수: #{result[:scraped_data][:recruitment].size}"
  puts "- 뉴스 수: #{result[:scraped_data][:news].size}"
  puts "- 기업 정보: #{result[:scraped_data][:basic_info].keys.join(', ')}"
end

puts "\n📌 메타데이터:"
puts result[:metadata].to_json

puts "\n✅ 테스트 완료!"