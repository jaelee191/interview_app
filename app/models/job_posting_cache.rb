class JobPostingCache < ApplicationRecord
  validates :url, presence: true, uniqueness: true
  
  # 캐시 유효기간: 24시간
  CACHE_DURATION = 24.hours
  
  # URL로 캐시된 콘텐츠 조회
  def self.fetch(url)
    cache = find_by(url: url)
    
    # 캐시가 있고 유효한 경우
    if cache && cache.still_valid?
      Rails.logger.info "캐시 히트: #{url}"
      return cache.content
    end
    
    # 캐시가 없거나 만료된 경우
    Rails.logger.info "캐시 미스: #{url}"
    nil
  end
  
  # 콘텐츠 캐싱
  def self.store(url, content)
    cache = find_or_initialize_by(url: url)
    cache.content = content
    cache.cached_at = Time.current
    cache.save!
    Rails.logger.info "캐시 저장: #{url}"
    content
  end
  
  # 캐시 유효성 검증
  def still_valid?
    cached_at && cached_at > CACHE_DURATION.ago
  end
  
  # 만료된 캐시 정리
  def self.cleanup_expired
    where("cached_at < ?", CACHE_DURATION.ago).destroy_all
  end
end