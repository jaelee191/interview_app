class CompanyNewsCrawlerJob < ApplicationJob
  queue_as :crawling
  
  def perform(company)
    Rails.logger.info "기업 뉴스 크롤링 시작: #{company.name}"
    
    crawler = CompanyNewsCrawlerService.new(company)
    news_items = crawler.crawl_all_sources
    
    saved_count = 0
    news_items.each do |news_data|
      begin
        company_news = CompanyNews.find_or_initialize_by(url: news_data[:url])
        
        if company_news.new_record?
          company_news.assign_attributes(news_data)
          if company_news.save
            saved_count += 1
          else
            Rails.logger.error "뉴스 저장 실패: #{company_news.errors.full_messages}"
          end
        end
      rescue StandardError => e
        Rails.logger.error "뉴스 처리 중 오류: #{e.message}"
      end
    end
    
    Rails.logger.info "#{company.name} 기업 뉴스 #{saved_count}개 저장 완료"
  end
end