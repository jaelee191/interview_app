require 'nokogiri'
require 'httparty'
require 'ferrum'

class CompanyNewsCrawlerService
  def initialize(company)
    @company = company
  end

  def crawl_all_sources
    news_items = []
    
    # 네이버 뉴스 검색
    news_items.concat(crawl_naver_news)
    
    # 구글 뉴스 검색
    news_items.concat(crawl_google_news)
    
    # 다음 뉴스 검색
    news_items.concat(crawl_daum_news)
    
    news_items
  end

  private

  def crawl_naver_news
    query = URI.encode_www_form_component(@company.name)
    url = "https://search.naver.com/search.naver?where=news&query=#{query}"
    
    response = HTTParty.get(url, {
      headers: {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
      }
    })
    
    return [] unless response.success?
    
    doc = Nokogiri::HTML(response.body)
    news_items = []
    
    doc.css('.news_tit').each_with_index do |element, index|
      break if index >= 20 # 최대 20개 기사
      
      title = element.text.strip
      link = element['href']
      
      # 기사 본문 페이지 크롤링
      article_data = fetch_article_details(link)
      
      news_items << {
        company: @company,
        title: title,
        url: link,
        source: 'naver',
        content: article_data[:content],
        summary: article_data[:summary],
        published_at: article_data[:published_at] || Time.current,
        sentiment: analyze_sentiment(title + " " + (article_data[:content] || ""))
      }
    end
    
    news_items
  rescue StandardError => e
    Rails.logger.error "네이버 뉴스 크롤링 실패: #{e.message}"
    []
  end

  def crawl_google_news
    query = URI.encode_www_form_component(@company.name)
    url = "https://news.google.com/search?q=#{query}&hl=ko&gl=KR&ceid=KR:ko"
    
    browser = Ferrum::Browser.new(
      headless: true,
      timeout: 30,
      window_size: [1920, 1080]
    )
    
    browser.go_to(url)
    browser.network.wait_for_idle(duration: 2)
    
    doc = Nokogiri::HTML(browser.body)
    news_items = []
    
    doc.css('article').each_with_index do |article, index|
      break if index >= 20
      
      title_element = article.css('h3').first
      next unless title_element
      
      title = title_element.text.strip
      link_element = article.css('a').first
      link = link_element ? "https://news.google.com#{link_element['href'].gsub('./', '/')}" : nil
      
      news_items << {
        company: @company,
        title: title,
        url: link || "#",
        source: 'google',
        content: nil,
        summary: article.css('.xBbh9').first&.text&.strip,
        published_at: parse_relative_time(article.css('time').first&.text),
        sentiment: analyze_sentiment(title)
      }
    end
    
    browser.quit
    news_items
  rescue StandardError => e
    Rails.logger.error "구글 뉴스 크롤링 실패: #{e.message}"
    browser&.quit
    []
  end

  def crawl_daum_news
    query = URI.encode_www_form_component(@company.name)
    url = "https://search.daum.net/search?w=news&q=#{query}"
    
    response = HTTParty.get(url, {
      headers: {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
      }
    })
    
    return [] unless response.success?
    
    doc = Nokogiri::HTML(response.body)
    news_items = []
    
    doc.css('.c-list-basic li').each_with_index do |item, index|
      break if index >= 20
      
      title_element = item.css('.tit-g').first
      next unless title_element
      
      title = title_element.text.strip
      link = title_element.css('a').first&.attr('href')
      summary = item.css('.desc').first&.text&.strip
      
      news_items << {
        company: @company,
        title: title,
        url: link || "#",
        source: 'daum',
        content: nil,
        summary: summary,
        published_at: Time.current,
        sentiment: analyze_sentiment(title + " " + (summary || ""))
      }
    end
    
    news_items
  rescue StandardError => e
    Rails.logger.error "다음 뉴스 크롤링 실패: #{e.message}"
    []
  end

  def fetch_article_details(url)
    return {} unless url
    
    response = HTTParty.get(url, {
      headers: {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
      },
      timeout: 10
    })
    
    return {} unless response.success?
    
    doc = Nokogiri::HTML(response.body)
    
    {
      content: extract_content(doc),
      summary: extract_summary(doc),
      published_at: extract_date(doc)
    }
  rescue StandardError => e
    Rails.logger.error "기사 상세 크롤링 실패: #{e.message}"
    {}
  end

  def extract_content(doc)
    selectors = [
      '#articleBodyContents',
      '.article_body',
      '.news_end',
      '#articeBody',
      '.article_view'
    ]
    
    selectors.each do |selector|
      element = doc.at(selector)
      return clean_text(element.text) if element
    end
    
    nil
  end

  def extract_summary(doc)
    doc.at('meta[property="og:description"]')&.attr('content') ||
    doc.at('meta[name="description"]')&.attr('content')
  end

  def extract_date(doc)
    date_string = doc.at('meta[property="article:published_time"]')&.attr('content') ||
                  doc.at('.article_info .num')&.text ||
                  doc.at('time')&.attr('datetime')
    
    return nil unless date_string
    
    DateTime.parse(date_string)
  rescue
    nil
  end

  def clean_text(text)
    text.gsub(/\s+/, ' ').strip.slice(0, 5000) # 최대 5000자
  end

  def analyze_sentiment(text)
    return 'neutral' unless text
    
    positive_keywords = ['성장', '상승', '증가', '호재', '긍정', '성공', '달성', '수익', '이익', '개선']
    negative_keywords = ['하락', '감소', '부진', '악재', '우려', '실패', '손실', '적자', '위기', '논란']
    
    text_lower = text.downcase
    
    positive_count = positive_keywords.count { |word| text.include?(word) }
    negative_count = negative_keywords.count { |word| text.include?(word) }
    
    if positive_count > negative_count
      'positive'
    elsif negative_count > positive_count
      'negative'
    else
      'neutral'
    end
  end

  def parse_relative_time(time_str)
    return Time.current unless time_str
    
    if time_str.include?('시간 전')
      hours = time_str.scan(/\d+/).first.to_i
      hours.hours.ago
    elsif time_str.include?('일 전')
      days = time_str.scan(/\d+/).first.to_i
      days.days.ago
    elsif time_str.include?('분 전')
      minutes = time_str.scan(/\d+/).first.to_i
      minutes.minutes.ago
    else
      Time.current
    end
  end
end