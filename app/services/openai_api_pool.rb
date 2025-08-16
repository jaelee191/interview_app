require 'singleton'
require 'concurrent'

class OpenaiApiPool
  include Singleton
  
  def initialize
    @api_keys = [
      ENV['OPENAI_API_KEY'],
      ENV['OPENAI_API_KEY_2'],
      ENV['OPENAI_API_KEY_3'],
      ENV['OPENAI_API_KEY_4']
    ].compact
    
    # 각 키별 사용 카운터 (Rate Limit 관리용)
    @usage_counters = Concurrent::Hash.new(0)
    
    # 각 키별 마지막 사용 시간
    @last_used = Concurrent::Hash.new(Time.now)
    
    # 각 키별 에러 카운터
    @error_counters = Concurrent::Hash.new(0)
    
    # 뮤텍스 for thread safety
    @mutex = Mutex.new
    
    Rails.logger.info "OpenAI API Pool initialized with #{@api_keys.size} keys"
  end
  
  # 가장 적게 사용된 키 반환 (Round-robin with load balancing)
  def get_available_key
    @mutex.synchronize do
      # 에러가 적고 사용량이 적은 키 선택
      available_keys = @api_keys.select { |key| @error_counters[key] < 5 }
      
      if available_keys.empty?
        # 모든 키가 에러 상태면 리셋
        reset_error_counters
        available_keys = @api_keys
      end
      
      # 가장 적게 사용된 키 선택
      best_key = available_keys.min_by do |key|
        score = @usage_counters[key] * 1.0
        # 최근 1초 이내 사용했으면 패널티
        score += 100 if Time.now - @last_used[key] < 1
        score
      end
      
      # 사용 기록 업데이트
      @usage_counters[best_key] += 1
      @last_used[best_key] = Time.now
      
      best_key
    end
  end
  
  # 여러 개의 키 반환 (병렬 처리용)
  def get_multiple_keys(count)
    @mutex.synchronize do
      available_keys = @api_keys.select { |key| @error_counters[key] < 5 }
      
      # 요청된 수만큼 키 반환 (중복 허용)
      keys = []
      count.times do
        keys << get_available_key
      end
      keys.uniq.take(count)
    end
  end
  
  # API 호출 성공 기록
  def report_success(api_key)
    @mutex.synchronize do
      @error_counters[api_key] = 0
    end
  end
  
  # API 호출 실패 기록
  def report_error(api_key, error_message = nil)
    @mutex.synchronize do
      @error_counters[api_key] += 1
      Rails.logger.warn "API Key error: #{api_key[0..10]}... - #{error_message}"
      
      # 5번 이상 에러시 일시적으로 사용 중지
      if @error_counters[api_key] >= 5
        Rails.logger.error "API Key temporarily disabled due to errors: #{api_key[0..10]}..."
      end
    end
  end
  
  # 에러 카운터 리셋
  def reset_error_counters
    @error_counters.clear
    Rails.logger.info "Error counters reset for all API keys"
  end
  
  # 통계 정보
  def stats
    @mutex.synchronize do
      {
        total_keys: @api_keys.size,
        usage: @usage_counters.to_h,
        errors: @error_counters.to_h,
        last_used: @last_used.to_h
      }
    end
  end
  
  # Rate Limit 대기 (429 에러 시)
  def wait_for_rate_limit(api_key, wait_seconds = 20)
    @mutex.synchronize do
      @last_used[api_key] = Time.now + wait_seconds
      Rails.logger.info "Rate limit hit for key #{api_key[0..10]}..., waiting #{wait_seconds} seconds"
    end
    sleep(wait_seconds)
  end
end