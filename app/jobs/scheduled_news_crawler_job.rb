class ScheduledNewsCrawlerJob < ApplicationJob
  queue_as :crawling
  
  # 주기적으로 실행되는 크롤링 작업
  def perform
    Rails.logger.info "정기 뉴스 크롤링 시작: #{Time.current}"
    
    # 각 뉴스 소스별로 크롤링 작업 생성
    news_sources = [
      { name: 'naver', url: 'https://news.naver.com' },
      { name: 'daum', url: 'https://news.daum.net' },
      # 추가 뉴스 소스
    ]
    
    news_sources.each do |source|
      NewsCrawlerJob.perform_later(nil, source[:name])
    end
    
    # 오래된 기사 정리 (30일 이상)
    old_articles = Article.where('created_at < ?', 30.days.ago)
    deleted_count = old_articles.destroy_all.size
    
    Rails.logger.info "#{deleted_count}개의 오래된 기사 삭제됨"
  end
end