require 'nokogiri'
require 'httparty'
require 'ferrum'

class NewsCrawlerService
  def initialize(source = nil)
    @source = source
  end

  # 정적 HTML 크롤링 (대부분의 뉴스 사이트)
  def crawl_static(url)
    response = HTTParty.get(url, {
      headers: {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
      }
    })
    
    return nil unless response.success?
    
    doc = Nokogiri::HTML(response.body)
    parse_article(doc, url)
  rescue StandardError => e
    Rails.logger.error "크롤링 실패: #{e.message}"
    nil
  end

  # 동적 콘텐츠 크롤링 (JavaScript 렌더링 필요한 사이트)
  def crawl_dynamic(url)
    browser = Ferrum::Browser.new(
      headless: true,
      timeout: 30,
      window_size: [1920, 1080]
    )
    
    browser.go_to(url)
    browser.network.wait_for_idle
    
    html = browser.body
    doc = Nokogiri::HTML(html)
    
    article = parse_article(doc, url)
    browser.quit
    
    article
  rescue StandardError => e
    Rails.logger.error "동적 크롤링 실패: #{e.message}"
    browser&.quit
    nil
  end

  # 여러 뉴스 사이트 크롤링
  def crawl_multiple_sources
    sources = {
      naver: "https://news.naver.com",
      daum: "https://news.daum.net",
      # 추가 뉴스 소스
    }
    
    articles = []
    sources.each do |name, base_url|
      case name
      when :naver
        articles.concat(crawl_naver_news)
      when :daum
        articles.concat(crawl_daum_news)
      end
    end
    
    articles
  end

  private

  def parse_article(doc, url)
    {
      title: extract_title(doc),
      content: extract_content(doc),
      url: url,
      source: extract_source(url),
      published_at: extract_date(doc),
      author: extract_author(doc),
      category: extract_category(doc),
      summary: extract_summary(doc),
      image_url: extract_image(doc)
    }
  end

  def extract_title(doc)
    # Open Graph 태그 우선
    doc.at('meta[property="og:title"]')&.attr('content') ||
    doc.at('title')&.text&.strip ||
    doc.at('h1')&.text&.strip
  end

  def extract_content(doc)
    # 일반적인 기사 본문 선택자들
    selectors = [
      'article', 
      '.article-body',
      '.news-content',
      '#articleBody',
      '.content',
      'main'
    ]
    
    selectors.each do |selector|
      element = doc.at(selector)
      return clean_text(element.text) if element
    end
    
    ""
  end

  def extract_source(url)
    URI.parse(url).host.gsub('www.', '')
  rescue
    "unknown"
  end

  def extract_date(doc)
    # Open Graph 또는 meta 태그에서 날짜 추출
    date_string = doc.at('meta[property="article:published_time"]')&.attr('content') ||
                  doc.at('time')&.attr('datetime') ||
                  doc.at('.date')&.text
    
    return nil unless date_string
    
    DateTime.parse(date_string)
  rescue
    nil
  end

  def extract_author(doc)
    doc.at('meta[name="author"]')&.attr('content') ||
    doc.at('.author')&.text&.strip ||
    doc.at('.reporter')&.text&.strip
  end

  def extract_category(doc)
    doc.at('meta[property="article:section"]')&.attr('content') ||
    doc.at('.category')&.text&.strip
  end

  def extract_summary(doc)
    doc.at('meta[property="og:description"]')&.attr('content') ||
    doc.at('meta[name="description"]')&.attr('content')
  end

  def extract_image(doc)
    doc.at('meta[property="og:image"]')&.attr('content') ||
    doc.at('img')&.attr('src')
  end

  def clean_text(text)
    text.gsub(/\s+/, ' ').strip
  end

  # 네이버 뉴스 크롤링
  def crawl_naver_news
    url = "https://news.naver.com/main/list.naver?mode=LSD&mid=sec&sid1=100"
    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)
    
    articles = []
    doc.css('.list_body .newsflash_body .type06_headline li').each do |item|
      link = item.at('a')&.attr('href')
      next unless link
      
      article_data = crawl_static(link)
      articles << article_data if article_data
    end
    
    articles
  rescue StandardError => e
    Rails.logger.error "네이버 뉴스 크롤링 실패: #{e.message}"
    []
  end

  # 다음 뉴스 크롤링
  def crawl_daum_news
    url = "https://news.daum.net"
    browser = Ferrum::Browser.new(headless: true)
    browser.go_to(url)
    
    doc = Nokogiri::HTML(browser.body)
    articles = []
    
    doc.css('.list_news2 a').each do |link|
      href = link.attr('href')
      next unless href
      
      article_data = crawl_dynamic(href)
      articles << article_data if article_data
    end
    
    browser.quit
    articles
  rescue StandardError => e
    Rails.logger.error "다음 뉴스 크롤링 실패: #{e.message}"
    []
  end
end