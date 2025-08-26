#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🚀 삼성전자 강화 기업 분석 테스트 시작..."
puts "=" * 50

# EnhancedCompanyAnalyzerService 테스트
service = EnhancedCompanyAnalyzerService.new("삼성전자")

puts "\n📊 분석 시작: #{Time.now}"
result = service.perform_enhanced_analysis

puts "\n✅ 분석 완료: #{Time.now}"
puts "=" * 50

# 결과 출력
puts "\n📌 Executive Summary (첫 1500자):"
puts result[:executive_summary][0..1500] if result[:executive_summary]

puts "\n" + "=" * 50

puts "\n📌 웹 크롤링 데이터:"
if result[:scraped_data]
  puts "- 채용공고 수: #{result[:scraped_data][:recruitment].size}"
  puts "- 뉴스 수: #{result[:scraped_data][:news].size}"
  
  if result[:scraped_data][:news].any?
    puts "\n🗞️ 최신 뉴스:"
    result[:scraped_data][:news].each_with_index do |news, i|
      puts "#{i+1}. #{news[:title]}"
      puts "   날짜: #{news[:date]}"
      puts ""
    end
  end
  
  if result[:scraped_data][:basic_info][:recent_keywords]
    puts "\n🔑 추출된 키워드:"
    puts result[:scraped_data][:basic_info][:recent_keywords].first(15).join(", ")
  end
end

puts "\n📌 메타데이터:"
puts "- 분석 버전: #{result[:metadata][:analysis_version]}"
puts "- 데이터 소스: #{result[:metadata][:data_sources].join(', ')}"
puts "- 에러: #{result[:metadata][:errors].any? ? result[:metadata][:errors] : '없음'}"

# 기업 개요 일부 출력
puts "\n" + "=" * 50
puts "\n📌 기업 개요 (첫 500자):"
puts result[:company_overview][0..500] if result[:company_overview]

puts "\n✅ 테스트 완료!"