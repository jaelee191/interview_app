require 'playwright'
require 'nokogiri'
require 'json'

class CompanyWebScraperService
  def initialize(company_name)
    @company_name = company_name
    @results = {
      basic_info: {},
      news: [],
      recruitment: [],
      reviews: [],
      financial: {},
      raw_data: []
    }
  end
  
  def scrape_all
    Rails.logger.info "🌐 Starting web scraping for: #{@company_name}"
    
    Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
      chromium = playwright.chromium
      browser = chromium.launch(headless: true)
      
      begin
        # 병렬로 여러 사이트 크롤링
        threads = []
        
        # 1. 잡코리아 크롤링
        threads << Thread.new do
          scrape_jobkorea(browser)
        rescue => e
          Rails.logger.error "JobKorea scraping error: #{e.message}"
        end
        
        # 2. 사람인 크롤링
        threads << Thread.new do
          scrape_saramin(browser)
        rescue => e
          Rails.logger.error "Saramin scraping error: #{e.message}"
        end
        
        # 3. 네이버 뉴스 크롤링
        threads << Thread.new do
          scrape_naver_news(browser)
        rescue => e
          Rails.logger.error "Naver news scraping error: #{e.message}"
        end
        
        # 4. 잡플래닛 리뷰 크롤링
        threads << Thread.new do
          scrape_jobplanet(browser)
        rescue => e
          Rails.logger.error "JobPlanet scraping error: #{e.message}"
        end
        
        # 모든 스레드 완료 대기
        threads.each(&:join)
        
      ensure
        browser.close
      end
    end
    
    Rails.logger.info "✅ Web scraping completed for: #{@company_name}"
    @results
  rescue => e
    Rails.logger.error "Web scraping failed: #{e.message}"
    @results[:error] = e.message
    @results
  end
  
  private
  
  def scrape_jobkorea(browser)
    Rails.logger.info "📍 Scraping JobKorea..."
    
    context = browser.new_context
    page = context.new_page
    
    # 잡코리아에서 기업 검색
    search_url = "https://www.jobkorea.co.kr/Search/?stext=#{URI.encode_www_form_component(@company_name)}"
    page.goto(search_url, wait_until: 'networkidle')
    
    # 검색 결과 대기
    page.wait_for_selector('.list-default', timeout: 10000) rescue nil
    
    # 채용공고 정보 수집
    job_listings = page.evaluate(<<~JS)
      Array.from(document.querySelectorAll('.list-default li')).slice(0, 5).map(item => ({
        title: item.querySelector('.title')?.innerText || '',
        company: item.querySelector('.name')?.innerText || '',
        location: item.querySelector('.loc')?.innerText || '',
        experience: item.querySelector('.exp')?.innerText || '',
        education: item.querySelector('.edu')?.innerText || '',
        deadline: item.querySelector('.date')?.innerText || '',
        url: item.querySelector('a')?.href || ''
      }))
    JS
    
    @results[:recruitment] = job_listings
    
    # 기업 정보 페이지로 이동 시도
    company_link = page.query_selector("a[href*='/company/']")
    if company_link
      company_link.click
      page.wait_for_load_state('networkidle')
      
      # 기업 기본 정보 수집
      company_info = page.evaluate(<<~JS)
        {
          name: document.querySelector('.company-name')?.innerText || '',
          industry: document.querySelector('.industry')?.innerText || '',
          size: document.querySelector('.company-size')?.innerText || '',
          founded: document.querySelector('.founded-year')?.innerText || '',
          employees: document.querySelector('.employee-count')?.innerText || '',
          description: document.querySelector('.company-description')?.innerText || ''
        }
      JS
      
      @results[:basic_info].merge!(company_info)
    end
    
    context.close
  end
  
  def scrape_saramin(browser)
    Rails.logger.info "📍 Scraping Saramin..."
    
    context = browser.new_context
    page = context.new_page
    
    # 사람인에서 기업 검색
    search_url = "https://www.saramin.co.kr/zf_user/search?searchword=#{URI.encode_www_form_component(@company_name)}&go=&flag=n&searchMode=1&searchType=search&search_done=y&search_optional_item=n"
    page.goto(search_url, wait_until: 'networkidle')
    
    # 기업 정보 탭 클릭
    company_tab = page.query_selector("a[data-tab='company']")
    if company_tab
      company_tab.click
      page.wait_for_selector('.content_col', timeout: 5000) rescue nil
      
      # 기업 정보 수집
      company_data = page.evaluate(<<~JS)
        {
          companyName: document.querySelector('.company_nm')?.innerText || '',
          industry: document.querySelector('.industry')?.innerText || '',
          ceo: document.querySelector('.ceo')?.innerText || '',
          website: document.querySelector('.homepage')?.innerText || '',
          address: document.querySelector('.address')?.innerText || '',
          employees: document.querySelector('.employee')?.innerText || ''
        }
      JS
      
      @results[:basic_info].merge!(company_data)
    end
    
    # 채용 정보 탭으로 이동
    recruit_tab = page.query_selector("a[data-tab='recruit']")
    if recruit_tab
      recruit_tab.click
      page.wait_for_selector('.recruit_list', timeout: 5000) rescue nil
      
      # 채용 정보 수집
      recruit_data = page.evaluate(<<~JS)
        Array.from(document.querySelectorAll('.recruit_list .item')).slice(0, 5).map(item => ({
          position: item.querySelector('.job_tit')?.innerText || '',
          experience: item.querySelector('.career')?.innerText || '',
          education: item.querySelector('.education')?.innerText || '',
          location: item.querySelector('.work_place')?.innerText || '',
          deadline: item.querySelector('.deadlines')?.innerText || ''
        }))
      JS
      
      @results[:recruitment].concat(recruit_data) if recruit_data.any?
    end
    
    context.close
  end
  
  def scrape_naver_news(browser)
    Rails.logger.info "📍 Scraping Naver News..."
    
    context = browser.new_context
    page = context.new_page
    
    # 네이버 뉴스 검색
    news_url = "https://search.naver.com/search.naver?where=news&query=#{URI.encode_www_form_component(@company_name)}"
    page.goto(news_url, wait_until: 'networkidle')
    
    # 뉴스 결과 대기
    page.wait_for_selector('.news_area', timeout: 5000) rescue nil
    
    # 최근 뉴스 수집 (최대 10개)
    news_data = page.evaluate(<<~JS)
      Array.from(document.querySelectorAll('.news_area')).slice(0, 10).map(item => ({
        title: item.querySelector('.news_tit')?.innerText || '',
        content: item.querySelector('.news_dsc')?.innerText || '',
        source: item.querySelector('.info_group .press')?.innerText || '',
        date: item.querySelector('.info_group span.info')?.innerText || '',
        url: item.querySelector('.news_tit')?.href || ''
      }))
    JS
    
    @results[:news] = news_data
    
    # 최신 뉴스에서 핵심 키워드 추출
    if news_data.any?
      keywords = extract_keywords_from_news(news_data)
      @results[:basic_info][:recent_keywords] = keywords
    end
    
    context.close
  end
  
  def scrape_jobplanet(browser)
    Rails.logger.info "📍 Scraping JobPlanet..."
    
    context = browser.new_context
    page = context.new_page
    
    # 잡플래닛 검색 (로그인 필요 없는 공개 정보만)
    search_url = "https://www.jobplanet.co.kr/search?query=#{URI.encode_www_form_component(@company_name)}"
    page.goto(search_url, wait_until: 'networkidle')
    
    # 기업 리뷰 요약 정보 수집
    page.wait_for_selector('.company_card', timeout: 5000) rescue nil
    
    review_summary = page.evaluate(<<~JS)
      {
        rating: document.querySelector('.rate_point')?.innerText || '',
        reviewCount: document.querySelector('.review_count')?.innerText || '',
        salary: document.querySelector('.salary_info')?.innerText || '',
        recommendation: document.querySelector('.recommend_rate')?.innerText || ''
      }
    JS
    
    @results[:reviews] = [review_summary] if review_summary[:rating].present?
    
    context.close
  end
  
  def extract_keywords_from_news(news_data)
    # 뉴스 제목과 내용에서 자주 나오는 키워드 추출
    text = news_data.map { |n| "#{n[:title]} #{n[:content]}" }.join(" ")
    
    # 불용어 제거
    stopwords = %w[의 를 이 가 은 는 과 와 으로 에서 에게 까지 부터 처럼 만큼 보다]
    
    # 단어 빈도 계산
    words = text.split(/\s+/)
                .map(&:downcase)
                .reject { |w| w.length < 2 || stopwords.include?(w) }
    
    word_freq = words.each_with_object(Hash.new(0)) { |word, hash| hash[word] += 1 }
    
    # 상위 10개 키워드 반환
    word_freq.sort_by { |_, count| -count }
             .first(10)
             .map(&:first)
  end
  
  def clean_text(text)
    text.to_s.strip.gsub(/\s+/, ' ')
  end
end