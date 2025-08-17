require 'net/http'
require 'json'
require 'concurrent'

class ParallelAnalysisService
  OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions'
  
  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    @model = ENV['OPENAI_MODEL'] || 'gpt-4o'
  end
  
  # ========== 방법 1: Thread 기반 병렬처리 ==========
  def analyze_with_threads(content)
    results = {}
    threads = []
    errors = []
    
    # 각 분석을 별도 스레드로 실행
    threads << Thread.new do
      begin
        results[:strengths] = analyze_strengths(content)
      rescue => e
        errors << { section: :strengths, error: e.message }
      end
    end
    
    threads << Thread.new do
      begin
        results[:improvements] = analyze_improvements(content)
      rescue => e
        errors << { section: :improvements, error: e.message }
      end
    end
    
    threads << Thread.new do
      begin
        results[:hidden_gems] = analyze_hidden_gems(content)
      rescue => e
        errors << { section: :hidden_gems, error: e.message }
      end
    end
    
    # 모든 스레드 완료 대기
    threads.each(&:join)
    
    # 결과 조합
    if errors.empty?
      {
        success: true,
        analysis: combine_results(results),
        execution_time: measure_time { threads.each(&:join) }
      }
    else
      { success: false, errors: errors }
    end
  end
  
  # ========== 방법 2: Concurrent Ruby 사용 ==========
  def analyze_with_concurrent(content)
    # Concurrent::Promise 사용
    promises = {
      strengths: Concurrent::Promise.execute { analyze_strengths(content) },
      improvements: Concurrent::Promise.execute { analyze_improvements(content) },
      hidden_gems: Concurrent::Promise.execute { analyze_hidden_gems(content) }
    }
    
    # 모든 Promise 완료 대기
    results = {}
    errors = []
    
    promises.each do |key, promise|
      if promise.fulfilled?
        results[key] = promise.value
      else
        errors << { section: key, error: promise.reason }
      end
    end
    
    if errors.empty?
      {
        success: true,
        analysis: combine_results(results)
      }
    else
      { success: false, errors: errors }
    end
  end
  
  # ========== 방법 3: 동시 HTTP 연결 풀 사용 ==========
  def analyze_with_connection_pool(content)
    require 'connection_pool'
    require 'typhoeus'
    
    hydra = Typhoeus::Hydra.new(max_concurrency: 3)
    requests = {}
    
    # 강점 분석 요청
    requests[:strengths] = create_typhoeus_request(
      build_prompt_for_strengths(content),
      "강점 분석 전문가"
    )
    hydra.queue(requests[:strengths])
    
    # 개선점 분석 요청
    requests[:improvements] = create_typhoeus_request(
      build_prompt_for_improvements(content),
      "개선점 분석 전문가"
    )
    hydra.queue(requests[:improvements])
    
    # 숨은 보석 분석 요청
    requests[:hidden_gems] = create_typhoeus_request(
      build_prompt_for_hidden_gems(content),
      "잠재력 발굴 전문가"
    )
    hydra.queue(requests[:hidden_gems])
    
    # 모든 요청 동시 실행
    hydra.run
    
    # 결과 수집
    results = {}
    requests.each do |key, request|
      if request.response.success?
        results[key] = JSON.parse(request.response.body)
      else
        return { success: false, error: "#{key} 분석 실패" }
      end
    end
    
    {
      success: true,
      analysis: combine_results(results)
    }
  end
  
  # ========== 방법 4: Async/Await 패턴 (Ruby 3.0+) ==========
  def analyze_with_async(content)
    require 'async'
    require 'async/http/internet'
    
    Async do
      internet = Async::HTTP::Internet.new
      
      # 비동기 태스크 생성
      tasks = [
        Async { fetch_analysis(internet, :strengths, content) },
        Async { fetch_analysis(internet, :improvements, content) },
        Async { fetch_analysis(internet, :hidden_gems, content) }
      ]
      
      # 모든 태스크 완료 대기
      results = tasks.map(&:wait)
      
      {
        success: true,
        analysis: combine_results(results)
      }
    ensure
      internet&.close
    end
  end
  
  # ========== 방법 5: Parallel 젬 사용 (가장 간단) ==========
  def analyze_with_parallel_gem(content)
    require 'parallel'
    
    sections = [:strengths, :improvements, :hidden_gems]
    
    # 병렬로 각 섹션 분석 실행
    results = Parallel.map(sections, in_threads: 3) do |section|
      case section
      when :strengths
        { section => analyze_strengths(content) }
      when :improvements
        { section => analyze_improvements(content) }
      when :hidden_gems
        { section => analyze_hidden_gems(content) }
      end
    end
    
    # 결과 병합
    merged_results = results.reduce({}, :merge)
    
    {
      success: true,
      analysis: combine_results(merged_results),
      method: 'parallel_gem'
    }
  end
  
  private
  
  # 각 섹션별 분석 메서드
  def analyze_strengths(content)
    prompt = build_prompt_for_strengths(content)
    response = make_api_request(prompt, "강점 분석 전문가", 3000)
    parse_response(response)[:content]
  end
  
  def analyze_improvements(content)
    prompt = build_prompt_for_improvements(content)
    response = make_api_request(prompt, "개선점 분석 전문가", 3000)
    parse_response(response)[:content]
  end
  
  def analyze_hidden_gems(content)
    prompt = build_prompt_for_hidden_gems(content)
    response = make_api_request(prompt, "잠재력 발굴 전문가", 2000)
    parse_response(response)[:content]
  end
  
  # 프롬프트 생성 메서드
  def build_prompt_for_strengths(content)
    <<~PROMPT
      자기소개서의 강점 5가지를 상세히 분석해주세요.
      각 강점마다 3-4문단으로 구체적으로 작성하세요.
      
      자기소개서:
      #{content}
    PROMPT
  end
  
  def build_prompt_for_improvements(content)
    <<~PROMPT
      자기소개서의 개선점 5가지를 상세히 분석해주세요.
      각 개선점마다 문제점, 이유, 개선방안을 포함해 3-4문단으로 작성하세요.
      
      자기소개서:
      #{content}
    PROMPT
  end
  
  def build_prompt_for_hidden_gems(content)
    <<~PROMPT
      자기소개서에서 놓치고 있는 숨은 강점 3가지를 발굴해주세요.
      각 항목마다 2-3문단으로 구체적으로 작성하세요.
      
      자기소개서:
      #{content}
    PROMPT
  end
  
  # API 요청 메서드
  def make_api_request(prompt, role_description, max_tokens = 3000)
    uri = URI(OPENAI_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60  # 개별 요청은 짧게
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      model: @model,
      messages: [
        {
          role: 'system',
          content: "당신은 #{role_description}입니다."
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.7,
      max_tokens: max_tokens
    }.to_json
    
    response = http.request(request)
    JSON.parse(response.body)
  end
  
  # Typhoeus 요청 생성 (방법 3용)
  def create_typhoeus_request(prompt, role)
    Typhoeus::Request.new(
      OPENAI_API_URL,
      method: :post,
      headers: {
        'Authorization' => "Bearer #{@api_key}",
        'Content-Type' => 'application/json'
      },
      body: {
        model: @model,
        messages: [
          { role: 'system', content: "당신은 #{role}입니다." },
          { role: 'user', content: prompt }
        ],
        temperature: 0.7,
        max_tokens: 3000
      }.to_json,
      timeout: 60
    )
  end
  
  # 비동기 분석 (방법 4용)
  def fetch_analysis(internet, section, content)
    # Async HTTP 구현
    # 실제 구현은 async-http 젬 필요
  end
  
  # 결과 병합
  def combine_results(results)
    <<~COMBINED
      ## 자기소개서 종합 분석 결과
      
      ### 📌 강점 분석
      #{results[:strengths]}
      
      ### 📌 개선점 분석
      #{results[:improvements]}
      
      ### 📌 숨은 보석들
      #{results[:hidden_gems]}
      
      ---
      분석 완료: #{Time.now}
    COMBINED
  end
  
  def parse_response(response)
    if response['error']
      { error: response['error']['message'] }
    elsif response['choices'] && response['choices'].first
      {
        success: true,
        content: response['choices'].first['message']['content']
      }
    else
      { error: '예상치 못한 응답 형식' }
    end
  end
  
  def measure_time
    start = Time.now
    yield
    Time.now - start
  end
end