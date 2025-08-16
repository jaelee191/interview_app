require 'net/http'
require 'json'
require 'concurrent'

class ParallelOpenaiService
  OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions'
  
  def initialize(model: nil)
    @api_pool = OpenaiApiPool.instance
    @model = model || ENV['OPENAI_MODEL'] || 'gpt-4o-mini'
    @executor = Concurrent::ThreadPoolExecutor.new(
      min_threads: 2,
      max_threads: 10,
      max_queue: 100,
      fallback_policy: :caller_runs
    )
  end
  
  # 단일 API 호출 (자동 키 선택)
  def call_api(prompt, system_prompt: nil, temperature: 0.7, max_tokens: 2000)
    api_key = @api_pool.get_available_key
    
    make_api_request(
      api_key: api_key,
      prompt: prompt,
      system_prompt: system_prompt,
      temperature: temperature,
      max_tokens: max_tokens
    )
  end
  
  # 병렬 API 호출 (여러 프롬프트 동시 처리)
  def parallel_calls(prompts, system_prompt: nil, temperature: 0.7, max_tokens: 2000)
    return [] if prompts.empty?
    
    # 사용 가능한 키 개수만큼 병렬 처리
    api_keys = @api_pool.get_multiple_keys([prompts.size, 4].min)
    
    futures = prompts.map.with_index do |prompt, index|
      api_key = api_keys[index % api_keys.size]
      
      Concurrent::Future.execute(executor: @executor) do
        make_api_request(
          api_key: api_key,
          prompt: prompt,
          system_prompt: system_prompt,
          temperature: temperature,
          max_tokens: max_tokens
        )
      end
    end
    
    # 모든 Future 완료 대기 (최대 60초)
    results = futures.map do |future|
      future.value(60) # 60초 타임아웃
    end
    
    results
  rescue => e
    Rails.logger.error "Parallel API calls failed: #{e.message}"
    prompts.map { { error: e.message } }
  end
  
  # 스트리밍 병렬 처리 (대량 데이터)
  def streaming_parallel_process(items, processor_block, batch_size: 4)
    results = Concurrent::Array.new
    
    items.each_slice(batch_size) do |batch|
      batch_futures = batch.map do |item|
        Concurrent::Future.execute(executor: @executor) do
          api_key = @api_pool.get_available_key
          processor_block.call(item, api_key)
        end
      end
      
      # 배치 완료 대기
      batch_results = batch_futures.map { |f| f.value(60) }
      results.concat(batch_results)
      
      # Rate limit 방지를 위한 짧은 대기
      sleep(0.5)
    end
    
    results.to_a
  end
  
  private
  
  def make_api_request(api_key:, prompt:, system_prompt: nil, temperature: 0.7, max_tokens: 2000, retry_count: 0)
    uri = URI(OPENAI_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 120  # 2분으로 증가
    http.open_timeout = 10
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{api_key}"
    request['Content-Type'] = 'application/json'
    
    messages = []
    messages << { role: 'system', content: system_prompt } if system_prompt
    messages << { role: 'user', content: prompt }
    
    request.body = {
      model: @model,
      messages: messages,
      temperature: temperature,
      max_tokens: max_tokens
    }.to_json
    
    response = http.request(request)
    result = JSON.parse(response.body)
    
    # 성공 처리
    if result['choices']
      @api_pool.report_success(api_key)
      {
        success: true,
        content: result['choices'].first['message']['content'],
        usage: result['usage'],
        model: result['model']
      }
    # Rate Limit 에러 처리
    elsif response.code == '429' && retry_count < 3
      wait_time = extract_wait_time(result)
      @api_pool.wait_for_rate_limit(api_key, wait_time)
      
      # 다른 키로 재시도
      new_api_key = @api_pool.get_available_key
      make_api_request(
        api_key: new_api_key,
        prompt: prompt,
        system_prompt: system_prompt,
        temperature: temperature,
        max_tokens: max_tokens,
        retry_count: retry_count + 1
      )
    else
      @api_pool.report_error(api_key, result['error']&.[]('message'))
      { success: false, error: result['error']&.[]('message') || 'Unknown error' }
    end
    
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    @api_pool.report_error(api_key, "Timeout: #{e.message}")
    
    if retry_count < 2
      # 다른 키로 재시도
      new_api_key = @api_pool.get_available_key
      make_api_request(
        api_key: new_api_key,
        prompt: prompt,
        system_prompt: system_prompt,
        temperature: temperature,
        max_tokens: max_tokens,
        retry_count: retry_count + 1
      )
    else
      { success: false, error: "Timeout after #{retry_count + 1} attempts" }
    end
    
  rescue => e
    @api_pool.report_error(api_key, e.message)
    { success: false, error: e.message }
  end
  
  def extract_wait_time(error_response)
    # Rate limit 응답에서 대기 시간 추출
    if error_response['error']&.[]('message')&.match(/try again in (\d+\.?\d*)s/)
      $1.to_f.ceil
    else
      20 # 기본 20초 대기
    end
  end
  
  # 리소스 정리
  def shutdown
    @executor.shutdown
    @executor.wait_for_termination(30)
  end
end