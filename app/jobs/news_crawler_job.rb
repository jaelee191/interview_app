class NewsCrawlerJob < ApplicationJob
  queue_as :crawling
  
  def perform(url, source = nil)
    crawler = NewsCrawlerService.new(source)
    
    # URL이 주어진 경우 단일 기사 크롤링
    if url.present?
      article_data = crawler.crawl_static(url)
      
      if article_data
        Article.create!(article_data)
        Rails.logger.info "기사 저장 완료: #{article_data[:title]}"
      end
    else
      # URL이 없으면 여러 소스에서 크롤링
      articles = crawler.crawl_multiple_sources
      
      articles.each do |article_data|
        Article.find_or_create_by(url: article_data[:url]) do |article|
          article.assign_attributes(article_data)
        end
      end
      
      Rails.logger.info "#{articles.size}개 기사 크롤링 완료"
    end
  rescue StandardError => e
    Rails.logger.error "크롤링 작업 실패: #{e.message}"
    raise # Sidekiq 재시도를 위해 에러 다시 발생
  end
end