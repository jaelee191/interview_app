#!/usr/bin/env ruby
require 'playwright'
require 'uri'

company_name = "카카오"
puts "🔍 #{company_name} 네이버 뉴스 테스트..."

Playwright.create(playwright_cli_executable_path: './node_modules/.bin/playwright') do |playwright|
  chromium = playwright.chromium
  browser = chromium.launch(headless: false) # 브라우저 보이게
  
  begin
    page = browser.new_page
    
    # 네이버 뉴스 검색
    news_url = "https://search.naver.com/search.naver?where=news&query=#{URI.encode_www_form_component(company_name)}"
    puts "Navigating to: #{news_url}"
    
    page.goto(news_url)
    
    # 페이지 로드 대기
    sleep 2
    
    # 뉴스 결과 대기
    begin
      page.wait_for_selector('.news_area', timeout: 5000)
      puts "✅ Found news articles"
    rescue
      puts "❌ No news articles found"
    end
    
    # JavaScript로 데이터 추출
    news_data = page.evaluate(<<~JS)
      Array.from(document.querySelectorAll('.news_area')).slice(0, 5).map(item => ({
        title: item.querySelector('.news_tit')?.innerText || '',
        content: item.querySelector('.news_dsc')?.innerText || '',
        source: item.querySelector('.info_group .press')?.innerText || '',
        date: item.querySelector('.info_group span.info')?.innerText || ''
      }))
    JS
    
    puts "\n📰 뉴스 결과:"
    news_data.each_with_index do |news, i|
      puts "#{i+1}. #{news['title']}"
      puts "   - #{news['source']} | #{news['date']}"
      puts ""
    end
    
    sleep 3 # 브라우저 보기 위해
    
  ensure
    browser.close
  end
end

puts "✅ 테스트 완료!"