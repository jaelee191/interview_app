#!/usr/bin/env ruby
require 'playwright'
require 'uri'

company_name = "카카오"
puts "📱 네이버 모바일 버전 크롤링 테스트..."

Playwright.create(playwright_cli_executable_path: './node_modules/.bin/playwright') do |playwright|
  # 모바일 디바이스 에뮬레이션
  device = playwright.devices['iPhone 13']
  
  chromium = playwright.chromium
  browser = chromium.launch(headless: false)
  
  begin
    # 모바일 컨텍스트로 생성
    context = browser.new_context(**device)
    page = context.new_page
    
    # 네이버 모바일 뉴스 검색
    mobile_news_url = "https://m.search.naver.com/search.naver?where=m_news&query=#{URI.encode_www_form_component(company_name)}"
    puts "URL: #{mobile_news_url}"
    
    page.goto(mobile_news_url)
    sleep 3
    
    # 모바일 페이지 구조 분석
    structure = page.evaluate(<<~JS)
      (() => {
        const result = {};
        
        // 모바일 셀렉터들
        result.news_list = document.querySelectorAll('.news_list').length;
        result.news_wrap = document.querySelectorAll('.news_wrap').length;
        result.total_tit = document.querySelectorAll('.total_tit').length;
        result.api_txt_lines = document.querySelectorAll('.api_txt_lines').length;
        result.news_tit = document.querySelectorAll('.news_tit').length;
        
        // 모든 링크 확인
        const links = document.querySelectorAll('a');
        result.total_links = links.length;
        
        // 뉴스 제목으로 보이는 링크들
        result.news_links = Array.from(links)
          .filter(a => a.innerText && a.innerText.length > 20)
          .slice(0, 5)
          .map(a => ({
            text: a.innerText.substring(0, 60),
            class: a.className
          }));
        
        return result;
      })()
    JS
    
    puts "\n📊 모바일 페이지 구조:"
    puts JSON.pretty_generate(structure)
    
    # 실제 뉴스 추출
    news_data = page.evaluate(<<~JS)
      (() => {
        // 뉴스 제목 찾기 - 여러 방법 시도
        const methods = [];
        
        // 방법 1: .news_tit 클래스
        const newsTits = Array.from(document.querySelectorAll('.news_tit'));
        if (newsTits.length > 0) {
          methods.push({
            method: '.news_tit',
            count: newsTits.length,
            titles: newsTits.slice(0, 3).map(el => el.innerText)
          });
        }
        
        // 방법 2: .total_tit 클래스
        const totalTits = Array.from(document.querySelectorAll('.total_tit'));
        if (totalTits.length > 0) {
          methods.push({
            method: '.total_tit',
            count: totalTits.length,
            titles: totalTits.slice(0, 3).map(el => el.innerText)
          });
        }
        
        // 방법 3: 링크 텍스트 기반
        const newsLinks = Array.from(document.querySelectorAll('a'))
          .filter(a => a.innerText && a.innerText.length > 20 && !a.innerText.includes('네이버'))
          .slice(0, 10);
        
        if (newsLinks.length > 0) {
          methods.push({
            method: 'filtered links',
            count: newsLinks.length,
            titles: newsLinks.slice(0, 5).map(a => a.innerText)
          });
        }
        
        return methods;
      })()
    JS
    
    puts "\n📰 뉴스 추출 결과:"
    news_data.each do |method|
      puts "\n방법: #{method['method']} (#{method['count']}개)"
      method['titles'].each_with_index do |title, i|
        puts "  #{i+1}. #{title[0..60]}"
      end
    end
    
    puts "\n브라우저 확인 (10초)..."
    sleep 10
    
  ensure
    browser.close
  end
end

puts "✅ 테스트 완료!"