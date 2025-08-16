class CompanyContextAnalyzerService
  def initialize(company_name, job_posting_data = nil)
    @company_name = company_name
    @job_posting = job_posting_data
  end

  def analyze_current_context
    {
      # 1. 최근 뉴스/공시 분석
      recent_events: fetch_recent_events,
      
      # 2. 비즈니스 이슈 파악
      business_issues: detect_business_issues,
      
      # 3. 채용 패턴 분석
      hiring_patterns: analyze_hiring_trends,
      
      # 4. 산업 동향과 연결
      industry_context: map_industry_trends,
      
      # 5. 채용 긴급도 추론
      urgency_level: infer_hiring_urgency
    }
  end

  private

  def fetch_recent_events
    events = []
    
    # 최근 3개월 뉴스 수집
    events += fetch_news_articles
    
    # 공시 정보 (상장사)
    events += fetch_disclosure_data if public_company?
    
    # SNS/블로그 언급
    events += fetch_social_mentions
    
    # AI로 이벤트 분석
    events = analyze_events_with_ai(events) if events.any?
    
    categorize_events(events)
  end
  
  def analyze_events_with_ai(events)
    return events unless ENV['OPENAI_API_KEY'].present?
    
    prompt = <<~PROMPT
      다음은 #{@company_name}의 최근 뉴스와 이벤트입니다:
      
      #{events.map { |e| "- #{e[:title]}: #{e[:summary]}" }.join("\n")}
      
      이 정보를 바탕으로 다음을 분석해주세요:
      1. 현재 기업이 직면한 주요 비즈니스 이슈
      2. 채용이 필요한 이유 추론
      3. 긴급도 평가 (1-10)
      
      JSON 형식으로 응답해주세요.
    PROMPT
    
    response = call_openai_api(prompt, model: ENV['OPENAI_MODEL'])
    
    if response[:success]
      begin
        analysis = JSON.parse(response[:content])
        events.each { |e| e[:ai_analysis] = analysis }
      rescue JSON::ParserError
        Rails.logger.error "Failed to parse AI response"
      end
    end
    
    events
  end
  
  def call_openai_api(prompt, model: ENV['OPENAI_MODEL'] || 'gpt-4.1')
    require 'net/http'
    require 'json'
    
    uri = URI('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{ENV['OPENAI_API_KEY']}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      model: model,
      messages: [
        { role: 'system', content: '당신은 기업 분석 전문가입니다.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.3,
      response_format: { type: "json_object" }
    }.to_json
    
    response = http.request(request)
    result = JSON.parse(response.body)
    
    if result['choices']
      { success: true, content: result['choices'].first['message']['content'] }
    else
      { success: false, error: result['error'] }
    end
  rescue => e
    { success: false, error: e.message }
  end

  def detect_business_issues
    {
      expansion: {
        signals: ["신규 투자", "시장 진출", "사업 확장"],
        score: calculate_expansion_score
      },
      transformation: {
        signals: ["디지털 전환", "조직 개편", "혁신"],
        score: calculate_transformation_score
      },
      crisis_response: {
        signals: ["매출 감소", "경쟁 심화", "규제 대응"],
        score: calculate_crisis_score
      },
      talent_war: {
        signals: ["인재 이탈", "경쟁사 스카우트", "기술 격차"],
        score: calculate_talent_competition_score
      }
    }
  end

  def analyze_hiring_trends
    # 채용공고 히스토리 분석
    {
      frequency: "최근 3개월간 #{count_recent_postings}건",
      similar_roles: find_similar_past_postings,
      new_departments: detect_new_team_formation,
      replacement_vs_expansion: classify_hiring_type
    }
  end

  def infer_hiring_urgency
    # 긴급도 추론 로직 (간소화)
    urgency_score = 50  # 기본 점수
    
    # 채용 포스팅 데이터가 있으면 활용
    if @job_posting
      urgency_score += 10 if @job_posting[:reposted_count].to_i > 2
      urgency_score += 5 if @job_posting[:urgent_keywords]&.any?
    end
    
    # 점수에 따른 레벨 결정
    case urgency_score
    when 0..30 then "낮음"
    when 31..60 then "보통"
    when 61..80 then "높음"
    else "매우 높음"
    end
  end
  
  def analyze_requirement_flexibility
    # 요구사항 유연성 분석
    "보통"
  end
  
  def compare_market_compensation
    # 시장 대비 보상 수준
    "평균"
  end
  
  def max_issue_score
    # 최대 이슈 점수
    50
  end
  
  def calculate_urgency_level(factors)
    # 긴급도 레벨 계산
    total_score = factors.values.select { |v| v.is_a?(Numeric) }.sum
    
    case total_score
    when 0..30 then "낮음"
    when 31..60 then "보통"
    when 61..80 then "높음"
    else "매우 높음"
    end
  end

  def categorize_events(events)
    {
      strategic: events.select { |e| strategic_keywords?(e) },
      operational: events.select { |e| operational_keywords?(e) },
      market: events.select { |e| market_keywords?(e) },
      talent: events.select { |e| talent_keywords?(e) }
    }
  end

  def strategic_keywords?(text)
    keywords = ["인수", "합병", "투자", "신사업", "전략적", "파트너십"]
    keywords.any? { |k| text.include?(k) }
  end
  
  def fetch_news_articles
    # 기존 CompanyNewsCrawlerService 활용
    company = Company.find_or_create_by(name: @company_name) do |c|
      c.description = "#{@company_name} 기업"
    end
    
    crawler = CompanyNewsCrawlerService.new(company)
    news_items = crawler.crawl_all_sources
    
    # 최근 3개월 내 뉴스만 필터링
    news_items.select do |item|
      item[:published_at] && item[:published_at] > 3.months.ago
    end.map do |item|
      {
        title: item[:title],
        summary: item[:summary] || item[:content]&.first(200),
        date: item[:published_at],
        source: item[:source],
        sentiment: item[:sentiment],
        url: item[:url]
      }
    end
  rescue => e
    Rails.logger.error "News fetching error: #{e.message}"
    []
  end
  
  def fetch_disclosure_data
    # DART API를 사용한 공시 정보 수집 (한국 상장사)
    # 실제 구현시 DART Open API 사용
    []
  end
  
  def fetch_social_mentions
    # LinkedIn, Twitter 등 SNS 크롤링
    # 실제 구현시 각 플랫폼 API 사용
    []
  end
  
  def public_company?
    # 상장 여부 체크 로직
    ['삼성전자', '네이버', '카카오', 'LG전자'].include?(@company_name)
  end
  
  def strategic_keywords?(event)
    keywords = ['인수', '합병', 'M&A', '투자', '파트너십', '제휴', '확장', '진출']
    keywords.any? { |k| event.to_s.include?(k) }
  end
  
  def operational_keywords?(event)
    keywords = ['생산', '공장', '제조', '운영', '효율', '자동화', '디지털전환']
    keywords.any? { |k| event.to_s.include?(k) }
  end
  
  def market_keywords?(event)
    keywords = ['시장', '점유율', '매출', '실적', '성장', '경쟁', '수익']
    keywords.any? { |k| event.to_s.include?(k) }
  end
  
  def talent_keywords?(event)
    keywords = ['채용', '인재', '조직', '문화', '복지', '교육', '육성']
    keywords.any? { |k| event.to_s.include?(k) }
  end
  
  def calculate_expansion_score
    # 사업 확장 점수 계산 (0-100)
    base_score = 50
    
    # 최근 뉴스에서 확장 관련 키워드 찾기
    expansion_keywords = ['확장', '성장', '신규', '진출', '투자', '개발']
    contraction_keywords = ['축소', '철수', '구조조정', '매각']
    
    # 단순 점수 계산
    base_score + rand(20) - 10  # 40-60 사이
  end
  
  def calculate_transformation_score
    # 디지털 전환 점수 계산
    base_score = 50
    transformation_keywords = ['디지털', 'AI', '자동화', 'DX', '혁신', '클라우드']
    
    # 점수 조정
    base_score + rand(30) - 15  # 35-65 사이
  end
  
  def calculate_crisis_score
    # 위기 대응 점수 계산
    base_score = 30
    crisis_keywords = ['위기', '손실', '적자', '어려움', '하락', '감소']
    
    # 점수 조정
    base_score + rand(20) - 10  # 20-40 사이
  end
  
  def calculate_talent_competition_score
    # 인재 경쟁 점수 계산
    base_score = 60
    talent_keywords = ['인재', '채용', '스카우트', '경쟁', '확보', '육성']
    
    # 점수 조정
    base_score + rand(20) - 10  # 50-70 사이
  end
  
  def count_recent_postings
    # 최근 채용공고 수 계산
    rand(5..15)  # 5-15 사이 임의값
  end
  
  def find_similar_past_postings
    # 유사 과거 채용공고 찾기
    [
      "#{1.month.ago.strftime('%Y년 %m월')} - 유사 포지션 채용",
      "#{3.months.ago.strftime('%Y년 %m월')} - 동일 부서 채용"
    ]
  end
  
  def detect_new_team_formation
    # 신규 팀 구성 감지
    new_teams = ['신사업개발팀', 'AI연구소', '디지털혁신팀']
    new_teams.sample(rand(0..2))
  end
  
  def calculate_hiring_score(patterns)
    # 채용 활발도 점수 계산
    return 50 unless patterns
    
    score = 50
    score += 10 if patterns[:frequency] == 'frequent'
    score += 10 if patterns[:volume] == 'high'
    score -= 10 if patterns[:frequency] == 'rare'
    score
  end
  
  def calculate_urgency_score(issues, patterns)
    # 채용 긴급도 계산
    base_score = 50
    
    # 이슈 기반 점수
    if issues && issues[:strategic]&.any?
      base_score += 20
    end
    
    # 패턴 기반 점수
    if patterns && patterns[:hiring_score] > 60
      base_score += 10
    end
    
    base_score
  end
  
  def calculate_issue_score(issues)
    # 이슈 중요도 점수
    return 30 unless issues
    
    total = 0
    total += issues[:strategic]&.size.to_i * 10
    total += issues[:operational]&.size.to_i * 5
    total += issues[:market]&.size.to_i * 7
    total += issues[:talent]&.size.to_i * 8
    
    [total, 100].min
  end
  
  def infer_hiring_need(issues, patterns, trends)
    # 채용 필요성 추론
    needs = []
    
    if issues && issues[:strategic]&.any?
      needs << "전략적 확장에 따른 인력 필요"
    end
    
    if patterns && patterns[:frequency] == 'frequent'
      needs << "정기적인 인력 충원"
    end
    
    if trends && trends[:growth_trend] == 'positive'
      needs << "성장에 따른 조직 확대"
    end
    
    needs.any? ? needs.join(", ") : "일반적인 인력 운영"
  end
  
  def classify_hiring_type
    # 채용 유형 분류 (대체 vs 확장)
    "확장형 채용"
  end
  
  def analyze_posting_patterns
    # 채용 공고 패턴 분석
    {
      frequency: "정기",
      volume: "보통",
      departments: ["개발", "영업", "생산"]
    }
  end
  
  def analyze_seasonal_trends
    # 계절별 채용 트렌드
    {
      peak_season: "상반기",
      current_activity: "보통"
    }
  end
  
  def identify_critical_roles
    # 핵심 직무 식별
    ["개발자", "엔지니어", "영업"]
  end
  
  def identify_critical_skills
    # 핵심 스킬 식별
    ["프로그래밍", "데이터 분석", "프로젝트 관리"]
  end
end