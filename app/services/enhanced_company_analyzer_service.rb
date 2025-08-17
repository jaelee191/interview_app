require 'net/http'
require 'json'

class EnhancedCompanyAnalyzerService
  def initialize(company_name)
    @company_name = company_name
    @api_key = ENV['OPENAI_API_KEY']
    @scraper = CompanyWebScraperService.new(company_name)
  end

  def perform_enhanced_analysis
    Rails.logger.info "🚀 Starting enhanced analysis with web scraping for: #{@company_name}"
    
    # 1단계: 웹 크롤링으로 실제 데이터 수집
    scraped_data = @scraper.scrape_all
    
    # 2단계: 크롤링 데이터를 기반으로 각 섹션 분석
    results = {}
    threads = []
    errors = []
    
    # 병렬 처리로 각 섹션 분석
    threads << Thread.new do
      begin
        results[:executive_summary] = generate_executive_summary(scraped_data)
      rescue => e
        errors << "Executive Summary: #{e.message}"
        results[:executive_summary] = nil
      end
    end
    
    threads << Thread.new do
      begin
        results[:company_overview] = analyze_company_overview(scraped_data)
      rescue => e
        errors << "Company Overview: #{e.message}"
        results[:company_overview] = nil
      end
    end
    
    threads << Thread.new do
      begin
        results[:industry_market] = analyze_industry_market(scraped_data)
      rescue => e
        errors << "Industry Market: #{e.message}"
        results[:industry_market] = nil
      end
    end
    
    threads << Thread.new do
      begin
        results[:hiring_strategy] = analyze_hiring_strategy(scraped_data)
      rescue => e
        errors << "Hiring Strategy: #{e.message}"
        results[:hiring_strategy] = nil
      end
    end
    
    threads << Thread.new do
      begin
        results[:job_preparation] = analyze_job_preparation(scraped_data)
      rescue => e
        errors << "Job Preparation: #{e.message}"
        results[:job_preparation] = nil
      end
    end
    
    threads << Thread.new do
      begin
        results[:competitor_comparison] = analyze_competitor_comparison(scraped_data)
      rescue => e
        errors << "Competitor Comparison: #{e.message}"
        results[:competitor_comparison] = nil
      end
    end
    
    threads << Thread.new do
      begin
        results[:consultant_advice] = generate_consultant_advice(scraped_data)
      rescue => e
        errors << "Consultant Advice: #{e.message}"
        results[:consultant_advice] = nil
      end
    end
    
    # 모든 스레드 완료 대기
    threads.each(&:join)
    
    # 에러 로깅
    if errors.any?
      Rails.logger.error "Enhanced Analysis Errors: #{errors.join(', ')}"
    end
    
    # 결과 조합
    {
      executive_summary: results[:executive_summary] || "분석 중 오류가 발생했습니다.",
      company_overview: results[:company_overview] || "분석 중 오류가 발생했습니다.",
      industry_market: results[:industry_market] || "분석 중 오류가 발생했습니다.",
      hiring_strategy: results[:hiring_strategy] || "분석 중 오류가 발생했습니다.",
      job_preparation: results[:job_preparation] || "분석 중 오류가 발생했습니다.",
      competitor_comparison: results[:competitor_comparison] || "분석 중 오류가 발생했습니다.",
      consultant_advice: results[:consultant_advice] || "분석 중 오류가 발생했습니다.",
      metadata: {
        analysis_date: Time.current,
        analysis_version: '5.0',
        methodology: 'Web Scraping + GPT-4 Enhanced Analysis',
        data_sources: extract_data_sources(scraped_data),
        model_used: ENV['OPENAI_MODEL'] || 'gpt-4',
        parallel_processing: true,
        parallel_threads: 7,
        web_scraping: true,
        errors: errors
      },
      scraped_data: scraped_data # 원본 크롤링 데이터도 포함
    }
  end

  private

  def extract_data_sources(scraped_data)
    sources = []
    sources << "JobKorea" if scraped_data[:recruitment].any?
    sources << "Saramin" if scraped_data[:basic_info][:companyName].present?
    sources << "Naver News" if scraped_data[:news].any?
    sources << "JobPlanet" if scraped_data[:reviews].any?
    sources
  end

  def generate_executive_summary(scraped_data)
    # 크롤링 데이터를 JSON으로 변환
    data_summary = prepare_data_summary(scraped_data)
    
    prompt = <<~PROMPT
      📌 기업분석 요약 (웹 크롤링 데이터 기반)
      기업명: #{@company_name}
      현재 날짜: #{Time.current.strftime('%Y년 %m월')}
      
      **실제 수집된 데이터:**
      #{data_summary}
      
      너는 경력 15년의 취업 컨설턴트다. 
      위의 실제 데이터를 바탕으로 취업 준비생이 #{@company_name}에 지원하기 전 반드시 알아야 할 핵심 정보를 요약하라.
      데이터가 없는 부분은 추측하지 말고 "정보 없음"으로 표시하라.
      
      ## 📊 한 눈에 보는 #{@company_name}
      
      ### 🎯 지원자가 꼭 알아야 할 3가지
      1. [실제 데이터 기반 현재 상황]
      2. [채용 공고 분석 기반 인재상]
      3. [뉴스 분석 기반 최신 동향]
      
      ### 💡 채용 트렌드 (실제 채용공고 기반)
      • 현재 채용 중인 포지션: [실제 공고 데이터]
      • 주력 채용 직무: [가장 많이 나온 직무]
      • 요구 경력: [신입/경력 비율]
      • 근무 지역: [실제 데이터]
      
      ### 📰 최신 뉴스 요약
      [수집된 뉴스 헤드라인 3개 요약]
      
      ### ⚡ 지원 전 체크리스트
      □ 최근 뉴스의 핵심 이슈를 파악했는가?
      □ 현재 채용 중인 직무와 내 역량이 매칭되는가?
      □ 기업 리뷰의 장단점을 확인했는가?
      
      실제 데이터만을 기반으로 작성하라. 추측이나 일반론은 배제하라.
    PROMPT

    call_gpt_api(prompt, max_tokens: 1500)
  end

  def analyze_company_overview(scraped_data)
    data_summary = prepare_data_summary(scraped_data)
    
    prompt = <<~PROMPT
      기업명: #{@company_name}
      현재 날짜: #{Time.current.strftime('%Y년 %m월')}
      
      **수집된 기업 정보:**
      #{data_summary}
      
      ## 1. 기업 개요 & 현황 (웹 크롤링 데이터 기반)
      
      위의 실제 데이터를 바탕으로 기업 개요를 작성하라.
      
      ### 기본 정보
      • 기업명: #{scraped_data[:basic_info][:name] || scraped_data[:basic_info][:companyName] || @company_name}
      • 업종: #{scraped_data[:basic_info][:industry] || "정보 없음"}
      • 규모: #{scraped_data[:basic_info][:size] || scraped_data[:basic_info][:employees] || "정보 없음"}
      • 대표: #{scraped_data[:basic_info][:ceo] || "정보 없음"}
      • 위치: #{scraped_data[:basic_info][:address] || "정보 없음"}
      • 홈페이지: #{scraped_data[:basic_info][:website] || "정보 없음"}
      
      ### 최근 동향 (뉴스 분석)
      [수집된 뉴스를 바탕으로 최근 3개월 주요 이슈 정리]
      
      ### 채용 현황
      [실제 채용공고 데이터 기반 현재 채용 동향]
      
      ### 기업 평판 (리뷰 데이터)
      [JobPlanet 등에서 수집한 평점과 리뷰 요약]
      
      **[취업 TIP]**
      → 실제 데이터를 보면 #{@company_name}는 현재 [핵심 특징]을 보이고 있습니다.
      자기소개서에서는 이러한 실제 상황을 반영한 지원동기를 작성하는 것이 중요합니다.
      
      데이터가 없는 부분은 "정보 수집 불가"로 명시하고, 추측하지 마라.
    PROMPT

    call_gpt_api(prompt, max_tokens: 2000)
  end

  def analyze_industry_market(scraped_data)
    data_summary = prepare_data_summary(scraped_data)
    
    prompt = <<~PROMPT
      기업명: #{@company_name}
      
      **수집된 데이터:**
      #{data_summary}
      
      ## 2. 시장 분석 (실제 데이터 기반)
      
      ### 뉴스에서 나타난 산업 트렌드
      [수집된 뉴스를 분석하여 업계 동향 파악]
      
      ### 채용 시장 분석
      • 채용 규모: [실제 공고 수 기반]
      • 주요 직무: [가장 많이 채용하는 포지션]
      • 요구 역량: [공고에서 추출한 키워드]
      • 경력 요구사항: [신입/경력 분포]
      
      ### 경쟁 환경 (뉴스 언급 기준)
      [뉴스에서 함께 언급된 경쟁사 분석]
      
      ### 기회와 위기 요인
      **기회 요인** (뉴스/공고 분석)
      • [실제 데이터에서 도출한 기회]
      
      **위기 요인** (뉴스 분석)
      • [부정적 뉴스나 이슈]
      
      수집된 데이터만을 기반으로 분석하고, 없는 정보는 명시하라.
    PROMPT

    call_gpt_api(prompt, max_tokens: 2000)
  end

  def analyze_hiring_strategy(scraped_data)
    # 채용 공고 데이터 정리
    job_data = extract_job_data(scraped_data)
    
    prompt = <<~PROMPT
      기업명: #{@company_name}
      
      **실제 채용 데이터:**
      #{job_data.to_json}
      
      ## 3. 채용 전략 분석 (실제 공고 기반)
      
      ### 현재 채용 중인 포지션
      #{format_job_listings(scraped_data[:recruitment])}
      
      ### 채용 패턴 분석
      • 총 채용 공고 수: #{scraped_data[:recruitment].size}
      • 주요 직무 분포: [데이터 기반 분석]
      • 경력 요구사항: [신입/경력 비율]
      • 근무 지역: [지역별 분포]
      • 마감일 패턴: [긴급/일반 채용 분석]
      
      ### 핵심 요구 역량 (공고 텍스트 분석)
      [실제 공고에서 추출한 주요 키워드와 역량]
      
      ### 기업 리뷰 기반 조직문화
      • 평점: #{scraped_data[:reviews].first&.dig(:rating) || "정보 없음"}
      • 추천율: #{scraped_data[:reviews].first&.dig(:recommendation) || "정보 없음"}
      • 평균 연봉: #{scraped_data[:reviews].first&.dig(:salary) || "정보 없음"}
      
      ### 지원 전략
      **서류 전형 대비**
      • 필수 키워드: [공고에서 추출한 키워드]
      • 우대 사항: [실제 우대사항 정리]
      
      **면접 대비**
      • 예상 질문: [기업 이슈 기반]
      • 준비 포인트: [뉴스와 공고 연계]
      
      실제 데이터만 사용하여 구체적으로 작성하라.
    PROMPT

    call_gpt_api(prompt, max_tokens: 3000)
  end

  def analyze_job_preparation(scraped_data)
    prompt = <<~PROMPT
      기업명: #{@company_name}
      
      **수집된 데이터 요약:**
      • 채용 공고 수: #{scraped_data[:recruitment].size}
      • 최신 뉴스 수: #{scraped_data[:news].size}
      • 기업 리뷰 데이터: #{scraped_data[:reviews].any? ? "있음" : "없음"}
      
      ## 4. 취업 준비 전략 (데이터 기반)
      
      ### 자기소개서 작성 가이드
      
      **필수 포함 키워드** (채용공고 분석)
      #{extract_keywords_from_jobs(scraped_data[:recruitment])}
      
      **최신 이슈 반영** (뉴스 분석)
      #{extract_key_news_points(scraped_data[:news])}
      
      ### 면접 준비 포인트
      
      **예상 질문** (데이터 기반)
      1. 최근 뉴스: "우리 회사의 [최신 이슈]에 대해 어떻게 생각하시나요?"
      2. 직무 이해: "현재 채용 중인 [주요 직무]에서 가장 중요한 역량은?"
      3. 지원 동기: "왜 지금 시점에 우리 회사에 지원했나요?"
      
      ### 포트폴리오 준비
      [채용 공고의 요구사항에 맞춘 포트폴리오 구성 제안]
      
      ### 차별화 전략
      • 최신 뉴스 숙지: [핵심 이슈 3개]
      • 채용 트렌드 파악: [현재 집중 채용 분야]
      • 기업 니즈 이해: [공고에서 도출한 니즈]
      
      데이터에 근거한 실용적 조언만 제공하라.
    PROMPT

    call_gpt_api(prompt, max_tokens: 2500)
  end

  def analyze_competitor_comparison(scraped_data)
    prompt = <<~PROMPT
      기업명: #{@company_name}
      
      ## 5. 경쟁 분석 (뉴스 데이터 기반)
      
      ### 뉴스에서 언급된 관련 기업
      [뉴스 분석을 통해 파악한 경쟁사나 협력사]
      
      ### #{@company_name}의 포지션
      • 시장 위치: [뉴스 톤 분석]
      • 주요 강점: [긍정적 뉴스 분석]
      • 개선 영역: [이슈나 과제]
      
      ### 채용 경쟁력
      • 채용 규모: #{scraped_data[:recruitment].size}개 포지션
      • 리뷰 평점: #{scraped_data[:reviews].first&.dig(:rating) || "정보 없음"}
      • 급여 수준: #{scraped_data[:reviews].first&.dig(:salary) || "정보 없음"}
      
      ### 차별화 포인트
      [실제 데이터에서 도출한 차별점]
      
      수집 가능한 데이터만으로 분석하라.
    PROMPT

    call_gpt_api(prompt, max_tokens: 2000)
  end

  def generate_consultant_advice(scraped_data)
    # 핵심 데이터 요약
    key_insights = {
      total_jobs: scraped_data[:recruitment].size,
      recent_news: scraped_data[:news].first(3).map { |n| n[:title] },
      company_rating: scraped_data[:reviews].first&.dig(:rating),
      main_keywords: extract_all_keywords(scraped_data)
    }
    
    prompt = <<~PROMPT
      기업명: #{@company_name}
      
      **핵심 인사이트:**
      #{key_insights.to_json}
      
      ## 6. 컨설턴트 최종 조언
      
      ### 🎯 데이터 기반 핵심 전략
      
      **1. 지금 지원해야 하는 이유**
      • 현재 채용 규모: #{key_insights[:total_jobs]}개 포지션
      • 최신 이슈: [뉴스 기반 분석]
      • 시장 상황: [데이터 기반 판단]
      
      **2. 차별화된 지원 전략**
      • 핵심 키워드 활용: #{key_insights[:main_keywords].first(5).join(', ') if key_insights[:main_keywords]}
      • 최신 이슈 언급: 필수
      • 데이터 기반 지원동기: 강력 추천
      
      **3. 주의사항**
      • 과장된 정보 주의 (실제 데이터와 대조)
      • 최신 뉴스 반드시 확인
      • 채용 공고 세부사항 숙지
      
      ### 📋 액션 플랜
      
      **즉시 실행 (오늘)**
      □ #{@company_name} 최신 뉴스 10개 정독
      □ 현재 채용공고 모두 저장
      □ 기업 리뷰 확인
      
      **1주일 내 완료**
      □ 채용공고 키워드 분석
      □ 자소서 초안 작성
      □ 포트폴리오 업데이트
      
      **지원 전 최종 체크**
      □ 최신 뉴스 업데이트 확인
      □ 자소서 키워드 매칭 검증
      □ 면접 예상질문 10개 준비
      
      ### 💡 성공 확률 높이기
      
      현재 데이터를 보면 #{@company_name}는:
      1. [가장 중요한 인사이트]
      2. [두 번째 인사이트]
      3. [세 번째 인사이트]
      
      이를 활용한 지원 전략을 수립하세요.
      
      실제 데이터에 기반한 구체적이고 실행 가능한 조언만 제공하라.
    PROMPT

    call_gpt_api(prompt, max_tokens: 3000)
  end

  # Helper methods
  def prepare_data_summary(scraped_data)
    summary = []
    
    if scraped_data[:basic_info].any?
      summary << "**기업 기본정보:**\n#{scraped_data[:basic_info].to_json}"
    end
    
    if scraped_data[:recruitment].any?
      summary << "**채용 공고 (#{scraped_data[:recruitment].size}개):**"
      scraped_data[:recruitment].first(3).each do |job|
        summary << "- #{job[:title] || job[:position]}: #{job[:experience]}, #{job[:location]}"
      end
    end
    
    if scraped_data[:news].any?
      summary << "**최신 뉴스 (#{scraped_data[:news].size}개):**"
      scraped_data[:news].first(3).each do |news|
        summary << "- #{news[:title]} (#{news[:date]})"
      end
    end
    
    if scraped_data[:reviews].any?
      summary << "**기업 리뷰:**\n#{scraped_data[:reviews].first.to_json}"
    end
    
    summary.join("\n\n")
  end

  def extract_job_data(scraped_data)
    {
      total_count: scraped_data[:recruitment].size,
      positions: scraped_data[:recruitment].map { |j| j[:title] || j[:position] }.compact,
      locations: scraped_data[:recruitment].map { |j| j[:location] }.compact.uniq,
      experience_levels: scraped_data[:recruitment].map { |j| j[:experience] }.compact.uniq
    }
  end

  def format_job_listings(jobs)
    return "현재 채용 정보 없음" if jobs.empty?
    
    jobs.first(5).map do |job|
      "• #{job[:title] || job[:position]}: #{job[:experience]}, #{job[:location]}, #{job[:deadline]}"
    end.join("\n")
  end

  def extract_keywords_from_jobs(jobs)
    return "키워드 추출 불가" if jobs.empty?
    
    all_text = jobs.map { |j| "#{j[:title]} #{j[:position]}" }.join(" ")
    words = all_text.split(/\s+/).map(&:downcase)
    word_freq = words.each_with_object(Hash.new(0)) { |word, hash| hash[word] += 1 }
    
    word_freq.sort_by { |_, count| -count }
             .first(10)
             .map { |word, count| "• #{word} (#{count}회)" }
             .join("\n")
  end

  def extract_key_news_points(news)
    return "최신 뉴스 없음" if news.empty?
    
    news.first(3).map do |item|
      "• #{item[:title]} - #{item[:source]} (#{item[:date]})"
    end.join("\n")
  end

  def extract_all_keywords(scraped_data)
    all_text = []
    all_text << scraped_data[:recruitment].map { |j| "#{j[:title]} #{j[:position]}" }.join(" ")
    all_text << scraped_data[:news].map { |n| n[:title] }.join(" ")
    
    text = all_text.join(" ")
    words = text.split(/\s+/).map(&:downcase).reject { |w| w.length < 2 }
    
    word_freq = words.each_with_object(Hash.new(0)) { |word, hash| hash[word] += 1 }
    word_freq.sort_by { |_, count| -count }.first(20).map(&:first)
  end

  def call_gpt_api(prompt, max_tokens: 2500)
    require 'net/http'
    require 'json'
    
    uri = URI('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 180
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      model: ENV['OPENAI_MODEL'] || 'gpt-4',
      messages: [
        { 
          role: 'system', 
          content: '당신은 웹 크롤링 데이터를 분석하는 전문가입니다. 
          실제 데이터만을 기반으로 분석하며, 추측이나 일반론은 배제합니다.
          데이터가 없는 부분은 명확히 "정보 없음"으로 표시합니다.' 
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.7,
      max_tokens: max_tokens
    }.to_json
    
    response = http.request(request)
    result = JSON.parse(response.body)
    
    if result['choices']
      result['choices'][0]['message']['content']
    else
      "분석 중 오류가 발생했습니다: #{result['error']&.dig('message')}"
    end
  rescue => e
    Rails.logger.error "GPT API Error: #{e.message}"
    "분석 중 오류가 발생했습니다: #{e.message}"
  end
end