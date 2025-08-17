#!/usr/bin/env ruby
require 'playwright'
require 'uri'

company_name = "카카오"
puts "🔍 네이버 뉴스 HTML 구조 분석..."

Playwright.create(playwright_cli_executable_path: './node_modules/.bin/playwright') do |playwright|
  chromium = playwright.chromium
  browser = chromium.launch(headless: false)
  
  begin
    page = browser.new_page
    
    # 네이버 뉴스 검색
    news_url = "https://search.naver.com/search.naver?where=news&query=#{URI.encode_www_form_component(company_name)}"
    puts "URL: #{news_url}"
    
    page.goto(news_url)
    sleep 3
    
    # 페이지 HTML 구조 확인
    html_structure = page.evaluate(<<~JS)
      (() => {
        const result = {};
        
        // 다양한 셀렉터 시도
        result['news_wrap'] = document.querySelectorAll('.news_wrap').length;
        result['list_news'] = document.querySelectorAll('.list_news').length;
        result['group_news'] = document.querySelectorAll('.group_news').length;
        result['news_area'] = document.querySelectorAll('.news_area').length;
        result['bx'] = document.querySelectorAll('.bx').length;
        
        // 제목 셀렉터
        result['news_tit'] = document.querySelectorAll('.news_tit').length;
        result['title_area'] = document.querySelectorAll('.title_area').length;
        
        // 실제 첫 번째 뉴스 제목 찾기
        const selectors = [
          'a.news_tit',
          '.news_tit',
          '.title_area a',
          '.news_wrap .title',
          'a[class*="tit"]'
        ];
        
        for (let selector of selectors) {
          const elem = document.querySelector(selector);
          if (elem && elem.innerText) {
            result['first_title'] = {
              selector: selector,
              text: elem.innerText.substring(0, 50)
            };
            break;
          }
        }
        
        return result;
      })()
    JS
    
    puts "\n📊 HTML 구조:"
    html_structure.each do |key, value|
      puts "  #{key}: #{value}"
    end
    
    # 실제 뉴스 데이터 추출 시도
    puts "\n📰 뉴스 추출 시도..."
    
    # 다양한 방법으로 시도
    news_data = page.evaluate(<<~JS)
      (() => {
        // 메인 뉴스 컨테이너 찾기
        const containers = document.querySelectorAll('.list_news > li, .group_news > ul > li');
        
        if (containers.length > 0) {
          return Array.from(containers).slice(0, 3).map(item => {
            const titleElem = item.querySelector('a.news_tit') || item.querySelector('.news_tit a') || item.querySelector('.title_area a');
            const descElem = item.querySelector('.news_dsc') || item.querySelector('.dsc_wrap') || item.querySelector('.api_txt_lines');
            const sourceElem = item.querySelector('.info_group .press') || item.querySelector('.press');
            const dateElem = item.querySelector('.info_group span') || item.querySelector('.info span');
            
            return {
              title: titleElem ? titleElem.innerText : '',
              desc: descElem ? descElem.innerText : '',
              source: sourceElem ? sourceElem.innerText : '',
              date: dateElem ? dateElem.innerText : ''
            };
          });
        }
        
        return [];
      })()
    JS
    
    if news_data.any?
      puts "✅ 뉴스 발견!"
      news_data.each_with_index do |news, i|
        puts "#{i+1}. #{news['title'][0..50]}"
        puts "   출처: #{news['source']}"
      end
    else
      puts "❌ 뉴스를 찾을 수 없음"
    end
    
    puts "\n브라우저에서 확인 후 5초 후 종료..."
    sleep 5
    
  ensure
    browser.close
  end
end