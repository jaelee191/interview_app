require 'net/http'
require 'json'
require 'nokogiri'

# 맥락 인식 채용공고 분석 서비스
# 기업의 시점적 배경과 채용 의도를 파악하여 차별화된 분석 제공
class ContextAwareAnalyzerService
  OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions'
  
  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    @model = ENV['OPENAI_MODEL'] || 'gpt-4.1'
  end
  
  # 기업 맥락 정보 수집 (뉴스, 투자, 사업 동향)
  def gather_company_context(company_name)
    context_data = {
      recent_news: [],
      business_trends: [],
      hiring_patterns: [],
      industry_insights: []
    }
    
    # 최근 뉴스 검색 (실제 구현시 뉴스 API 활용)
    context_data[:recent_news] = search_recent_news(company_name)
    
    # 산업 동향 분석
    context_data[:industry_insights] = analyze_industry_trends(company_name)
    
    # 채용 패턴 분석 (과거 채용 데이터 활용)
    context_data[:hiring_patterns] = analyze_hiring_patterns(company_name)
    
    context_data
  end
  
  # 채용 시점 의도 분석
  def analyze_hiring_intent(job_posting, company_context)
    prompt = build_intent_analysis_prompt(job_posting, company_context)
    
    response = make_api_request(prompt)
    parse_response(response)[:content]
  end
  
  # 경쟁사 움직임 분석
  def analyze_competitor_movements(company_name, industry)
    competitors = identify_competitors(company_name, industry)
    
    movements = competitors.map do |competitor|
      {
        company: competitor,
        recent_hires: analyze_recent_hires(competitor),
        expansion_areas: identify_expansion_areas(competitor)
      }
    end
    
    movements
  end
  
  # 온톨로지 기반 역량 매핑
  def map_skills_to_ontology(required_skills)
    # ESCO 또는 커스텀 온톨로지 활용
    skill_ontology = load_skill_ontology
    
    mapped_skills = required_skills.map do |skill|
      {
        original: skill,
        category: categorize_skill(skill, skill_ontology),
        related_skills: find_related_skills(skill, skill_ontology),
        importance_level: calculate_importance(skill)
      }
    end
    
    mapped_skills
  end
  
  # 차별화된 채용공고 분석
  def analyze_with_context(job_posting_url, company_name = nil)
    # 1. 기본 채용공고 내용 수집
    posting_content = fetch_job_posting(job_posting_url)
    
    # 2. 기업 맥락 정보 수집
    company_name ||= extract_company_name(posting_content)
    company_context = gather_company_context(company_name)
    
    # 3. 채용 의도 분석
    hiring_intent = analyze_hiring_intent(posting_content, company_context)
    
    # 4. 경쟁사 동향 분석
    competitor_movements = analyze_competitor_movements(
      company_name, 
      extract_industry(posting_content)
    )
    
    # 5. 역량 온톨로지 매핑
    required_skills = extract_required_skills(posting_content)
    skill_mapping = map_skills_to_ontology(required_skills)
    
    # 6. 종합 분석 생성
    comprehensive_analysis = generate_contextual_analysis(
      posting_content,
      company_context,
      hiring_intent,
      competitor_movements,
      skill_mapping
    )
    
    {
      success: true,
      analysis: comprehensive_analysis,
      context: {
        company_situation: company_context,
        hiring_intent: hiring_intent,
        market_position: competitor_movements,
        skill_requirements: skill_mapping
      },
      recommendations: generate_strategic_recommendations(comprehensive_analysis)
    }
  end
  
  private
  
  def search_recent_news(company_name)
    # 실제 구현시 네이버 뉴스 API 또는 구글 뉴스 API 활용
    # 여기서는 샘플 데이터 반환
    [
      {
        title: "#{company_name}, AI 사업 본격 진출 선언",
        date: 1.week.ago,
        relevance: "high",
        keywords: ["AI", "신사업", "투자"]
      },
      {
        title: "#{company_name}, 글로벌 시장 확대 전략 발표",
        date: 2.weeks.ago,
        relevance: "medium",
        keywords: ["글로벌", "확장", "성장"]
      }
    ]
  end
  
  def analyze_industry_trends(company_name)
    # 산업 트렌드 분석 로직
    {
      growth_areas: ["AI/ML", "클라우드", "ESG"],
      declining_areas: ["레거시 시스템", "오프라인 중심"],
      key_technologies: ["생성AI", "자동화", "데이터 분석"],
      market_challenges: ["인재 확보 경쟁", "기술 변화 속도"]
    }
  end
  
  def analyze_hiring_patterns(company_name)
    # 과거 채용 패턴 분석
    {
      recent_positions: ["AI 엔지니어", "데이터 사이언티스트", "프로덕트 매니저"],
      hiring_frequency: "증가 추세",
      preferred_experience: "3-7년차",
      team_expansion: ["AI팀", "데이터팀"]
    }
  end
  
  def build_intent_analysis_prompt(job_posting, company_context)
    <<~PROMPT
      당신은 기업 전략과 채용 의도를 분석하는 전문가입니다.
      
      다음 정보를 바탕으로 이 채용의 숨겨진 의도와 맥락을 분석해주세요:
      
      **채용공고 내용**:
      #{job_posting}
      
      **기업 최근 동향**:
      - 최근 뉴스: #{company_context[:recent_news].map { |n| n[:title] }.join(", ")}
      - 산업 트렌드: #{company_context[:industry_insights][:growth_areas].join(", ")}
      - 채용 패턴: #{company_context[:hiring_patterns][:recent_positions].join(", ")}
      
      다음을 분석해주세요:
      
      ## 🎯 채용 의도 분석
      
      ### 현재 기업 상황
      - 왜 지금 이 시점에 채용하는가?
      - 어떤 비즈니스 목표와 연결되는가?
      - 조직 내 어떤 변화를 암시하는가?
      
      ### 숨겨진 요구사항
      - 명시되지 않았지만 중요한 역량은?
      - 실제로 해결하려는 문제는 무엇인가?
      - 기대하는 임팩트는 무엇인가?
      
      ### 전략적 포지셔닝
      - 이 포지션이 회사에서 갖는 중요도는?
      - 향후 커리어 성장 가능성은?
      - 핵심 프로젝트 참여 가능성은?
      
      ### 시장 맥락
      - 경쟁사 대비 차별화 포인트는?
      - 산업 트렌드와의 연관성은?
      - 미래 성장 가능성은?
    PROMPT
  end
  
  def generate_contextual_analysis(posting, context, intent, competitors, skills)
    prompt = <<~PROMPT
      다음 정보를 종합하여 차별화된 채용공고 분석을 생성해주세요:
      
      **채용공고**: #{posting[0..1000]}
      **기업 상황**: #{context.to_json[0..500]}
      **채용 의도**: #{intent[0..500]}
      **경쟁사 동향**: #{competitors.to_json[0..300]}
      **역량 매핑**: #{skills.to_json[0..300]}
      
      ## 📊 맥락 기반 채용공고 분석
      
      ### 🔍 핵심 인사이트
      **"왜 지금, 이 인재가 필요한가?"**
      [기업의 현재 상황과 채용 배경을 2-3문장으로 설명]
      
      ### 💡 숨겨진 기회
      **이 포지션의 진짜 가치**
      - 단순 직무 수행을 넘어선 성장 기회
      - 회사의 핵심 프로젝트 참여 가능성
      - 미래 커리어 발전 경로
      
      ### 🎯 맞춤형 준비 전략
      **차별화된 지원 전략**
      1. [기업 상황에 맞춘 스토리텔링 방법]
      2. [시장 트렌드를 활용한 역량 어필]
      3. [경쟁자와 차별화되는 포지셔닝]
      
      ### 🚀 성공 가능성 극대화
      **핵심 성공 요인**
      - 꼭 강조해야 할 경험: [구체적 경험 유형]
      - 필수 준비 사항: [기업 특화 준비]
      - 차별화 포인트: [독특한 강점 어필 방법]
      
      ### ⚡ 액션 아이템
      1. **즉시 실행**: [바로 준비할 사항]
      2. **단기 준비**: [1-2주 내 준비 사항]
      3. **심화 준비**: [면접 전까지 준비 사항]
      
      ### 🎪 위험 요소 및 대응
      - 주의할 점: [피해야 할 실수]
      - 예상 경쟁: [경쟁 강도와 대응 방법]
      - 대안 전략: [Plan B 수립]
      
      ---
      💬 **전문가 조언**: [이 채용의 핵심을 꿰뚫는 한 줄 조언]
    PROMPT
    
    response = make_api_request(prompt)
    parse_response(response)[:content]
  end
  
  def generate_strategic_recommendations(analysis)
    {
      immediate_actions: [
        "기업 최근 뉴스와 사업 방향 깊이 있게 조사",
        "핵심 키워드를 활용한 경험 스토리 준비",
        "온톨로지 매핑된 역량 중심으로 자소서 구성"
      ],
      differentiation_strategies: [
        "시장 트렌드와 개인 경험 연결",
        "기업의 현재 과제에 대한 솔루션 제시",
        "경쟁사 대비 차별화된 가치 제안"
      ],
      risk_mitigation: [
        "과도한 기술 나열 지양",
        "구체적 성과와 숫자로 신뢰성 확보",
        "기업 문화와 가치관 일치 강조"
      ]
    }
  end
  
  def identify_competitors(company_name, industry)
    # 실제 구현시 산업별 경쟁사 DB 활용
    case industry
    when /IT|테크|소프트웨어/
      ["네이버", "카카오", "쿠팡", "토스"]
    when /금융|은행/
      ["KB국민은행", "신한은행", "하나은행", "우리은행"]
    when /제조|전자/
      ["삼성전자", "LG전자", "SK하이닉스", "현대차"]
    else
      ["경쟁사A", "경쟁사B", "경쟁사C"]
    end
  end
  
  def analyze_recent_hires(company)
    # 링크드인 API 또는 잡플래닛 데이터 활용
    {
      recent_positions: ["시니어 개발자", "프로덕트 매니저"],
      hiring_volume: "증가",
      focus_areas: ["AI", "데이터"]
    }
  end
  
  def identify_expansion_areas(company)
    ["AI 서비스", "글로벌 진출", "신사업 개발"]
  end
  
  def load_skill_ontology
    # ESCO 또는 커스텀 온톨로지 로드
    {
      "programming" => {
        "languages" => ["Python", "Java", "JavaScript"],
        "frameworks" => ["React", "Spring", "Django"]
      },
      "soft_skills" => {
        "leadership" => ["팀 리딩", "프로젝트 관리", "의사결정"],
        "communication" => ["프레젠테이션", "문서 작성", "협업"]
      }
    }
  end
  
  def categorize_skill(skill, ontology)
    # 스킬을 온톨로지 카테고리로 분류
    skill.downcase.include?("python") ? "programming/languages" : "general"
  end
  
  def find_related_skills(skill, ontology)
    # 관련 스킬 찾기
    ["유사 스킬1", "유사 스킬2"]
  end
  
  def calculate_importance(skill)
    # 스킬 중요도 계산 (시장 수요, 희소성 등 고려)
    rand(1..10)
  end
  
  def extract_company_name(content)
    # 채용공고에서 회사명 추출
    content.match(/회사:\s*(.+?)[\n\r]/)&.captures&.first || "Unknown Company"
  end
  
  def extract_industry(content)
    # 채용공고에서 산업 분야 추출
    content.match(/산업|업종|분야:\s*(.+?)[\n\r]/)&.captures&.first || "General"
  end
  
  def extract_required_skills(content)
    # 채용공고에서 요구 스킬 추출
    skills = []
    
    # 기술 스택 패턴
    if content.match(/필수[^:]*:(.+?)(?:우대|자격|$)/m)
      skills += $1.scan(/[A-Za-z]+(?:\s+[A-Za-z]+)?/)
    end
    
    skills.uniq
  end
  
  def fetch_job_posting(url)
    # 기존 JobPostingAnalyzerService 활용
    analyzer = JobPostingAnalyzerService.new
    result = analyzer.analyze_job_posting(url)
    
    result[:raw_content] || ""
  end
  
  def make_api_request(prompt)
    uri = URI(OPENAI_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      model: @model,
      messages: [
        {
          role: 'system',
          content: '당신은 기업 전략과 채용 맥락을 깊이 이해하는 HR 인텔리전스 전문가입니다.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.7,
      max_tokens: 3000
    }.to_json
    
    response = http.request(request)
    JSON.parse(response.body)
  end
  
  def parse_response(response)
    if response['error']
      { error: response['error']['message'] }
    elsif response['choices'] && response['choices'].first
      {
        success: true,
        content: response['choices'].first['message']['content'],
        usage: response['usage']
      }
    else
      { error: '예상치 못한 응답 형식입니다' }
    end
  end
end