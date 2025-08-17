#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🔍 카카오 웹 크롤링 디버그 테스트..."
puts "=" * 50

# CompanyWebScraperService 디버그
scraper = CompanyWebScraperService.new("카카오")

puts "\n📊 크롤링 시작: #{Time.now}"

begin
  result = scraper.scrape_all
  
  puts "\n✅ 크롤링 완료: #{Time.now}"
  puts "=" * 50
  
  puts "\n📌 수집된 데이터:"
  puts "- 기본 정보: #{result[:basic_info]}"
  puts "- 채용공고 수: #{result[:recruitment].size}"
  puts "- 뉴스 수: #{result[:news].size}"
  puts "- 리뷰 정보: #{result[:reviews]}"
  
  if result[:recruitment].any?
    puts "\n📌 채용공고 샘플:"
    result[:recruitment].first(2).each do |job|
      puts "  - #{job[:title] || job[:position]}: #{job[:location]}"
    end
  end
  
  if result[:news].any?
    puts "\n📌 최신 뉴스:"
    result[:news].first(3).each do |news|
      puts "  - #{news[:title]} (#{news[:date]})"
    end
  end
  
  if result[:error]
    puts "\n❌ 에러 발생: #{result[:error]}"
  end
  
rescue => e
  puts "\n❌ 예외 발생: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\n✅ 디버그 테스트 완료!"