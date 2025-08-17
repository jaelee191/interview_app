#!/usr/bin/env ruby
require 'playwright'
require 'uri'

company_name = "카카오"
puts "🔍 네이버 뉴스 심층 분석..."

Playwright.create(playwright_cli_executable_path: './node_modules/.bin/playwright') do |playwright|
  chromium = playwright.chromium
  browser = chromium.launch(headless: false)
  
  begin
    page = browser.new_page
    
    # 네이버 뉴스 검색
    news_url = "https://search.naver.com/search.naver?where=news&query=#{URI.encode_www_form_component(company_name)}"
    page.goto(news_url)
    
    # 페이지 완전 로드 대기
    sleep 5
    
    # 전체 HTML 분석
    analysis = page.evaluate(<<~JS)
      (() => {
        const result = {};
        
        // list_news 내부 구조 분석
        const listNews = document.querySelector('.list_news');
        if (listNews) {
          result.listNews = {
            exists: true,
            children: listNews.children.length,
            innerHTML_sample: listNews.innerHTML.substring(0, 500)
          };
          
          // 첫 번째 아이템 분석
          const firstItem = listNews.querySelector('li');
          if (firstItem) {
            result.firstItem = {
              exists: true,
              className: firstItem.className,
              links: Array.from(firstItem.querySelectorAll('a')).map(a => ({
                className: a.className,
                text: a.innerText ? a.innerText.substring(0, 50) : '',
                href: a.href
              }))
            };
          }
        }
        
        // 모든 링크 찾기
        const allLinks = document.querySelectorAll('.list_news a');
        result.totalLinks = allLinks.length;
        result.linkSamples = Array.from(allLinks).slice(0, 3).map(a => ({
          class: a.className,
          text: a.innerText ? a.innerText.substring(0, 50) : ''
        }));
        
        return result;
      })()
    JS
    
    puts "\n📊 분석 결과:"
    puts JSON.pretty_generate(analysis)
    
    # 실제 뉴스 추출 - 더 단순한 방법
    news_titles = page.evaluate(<<~JS)
      Array.from(document.querySelectorAll('.list_news a')).
        filter(a => a.innerText && a.innerText.length > 10).
        slice(0, 5).
        map(a => a.innerText)
    JS
    
    puts "\n📰 추출된 뉴스 제목:"
    news_titles.each_with_index do |title, i|
      puts "#{i+1}. #{title[0..60]}"
    end
    
    puts "\n브라우저 확인 (10초)..."
    sleep 10
    
  ensure
    browser.close
  end
end