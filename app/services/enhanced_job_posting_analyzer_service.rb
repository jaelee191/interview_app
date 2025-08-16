require 'net/http'
require 'json'

class EnhancedJobPostingAnalyzerService
  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    @model = ENV['OPENAI_MODEL'] || 'gpt-4o'
    @parallel_service = ParallelOpenaiService.new
  end
  
  def perform_deep_analysis(company_name, position, job_content, url = nil)
    Rails.logger.info "=== 강화된 채용공고 분석 시작 ==="
    Rails.logger.info "Company: #{company_name}, Position: #{position}"
    
    # 병렬로 다각도 분석 실행
    futures = []
    
    # 1. 기업 최신 이슈 수집 (핵심!)
    futures << Concurrent::Future.execute do
      fetch_company_context(company_name)
    end
    
    # 2. 산업 동향 분석
    futures << Concurrent::Future.execute do
      analyze_industry_trends(company_name, position)
    end
    
    # 3. 경쟁사 분석 - 대기업만 수행
    is_large_company = check_if_large_company(company_name)
    if is_large_company
      futures << Concurrent::Future.execute do
        analyze_competitor_hiring(company_name)
      end
    end
    
    # 결과 수집 (타임아웃을 30초로 늘림)
    company_context = futures[0].value(30) || {}
    industry_trends = futures[1].value(30) || {}
    competitor_analysis = is_large_company ? (futures[2].value(30) || {}) : {}
    
    Rails.logger.info "Context collected: #{company_context.keys}"
    Rails.logger.info "Trends collected: #{industry_trends.keys}"
    Rails.logger.info "Is large company: #{is_large_company}"
    Rails.logger.info "Competitors analyzed: #{competitor_analysis.keys.any?}"
    
    # 통합 분석
    integrated_analysis = generate_comprehensive_analysis(
      company_name,
      position,
      job_content,
      company_context,
      industry_trends,
      competitor_analysis
    )
    
    integrated_analysis
  end
  
  private
  
  def fetch_company_context(company_name)
    begin
      # 먼저 캐시된 기업 분석 데이터 확인
      cached_analysis = CompanyAnalysis.by_company(company_name).recent.first
      
      if cached_analysis
        Rails.logger.info "Using cached company analysis for #{company_name}"
        return {
          recent_issues: JSON.parse(cached_analysis.recent_issues || '{}'),
          business_context: JSON.parse(cached_analysis.business_context || '{}'),
          from_cache: true,
          analysis_date: cached_analysis.analysis_date
        }
      end
      
      # 캐시가 없으면 새로 분석
      Rails.logger.info "No cache found, performing new analysis for #{company_name}"
      
      # 최근 3개월 이슈 수집
      recent_news = search_recent_news(company_name)
      
      return {} if recent_news.empty?
      
      # AI로 핵심 이슈 추출
      prompt = <<~PROMPT
        #{company_name}의 최근 뉴스를 분석하여 채용과 관련된 핵심 이슈를 추출하세요:
        
        #{recent_news.map { |n| "- #{n[:title]}" }.join("\n")}
        
        다음 관점에서 분석:
        1. 사업 확장/축소 동향
        2. 신규 프로젝트나 투자
        3. 조직 개편이나 구조조정
        4. 기술 도입이나 혁신
        5. 실적과 성장 전망
        6. 채용 긴급도 추정
      PROMPT
      
      response = @parallel_service.call_api(prompt, temperature: 0.3)
      
      {
        recent_issues: parse_company_issues(response[:content]),
        news_sources: recent_news,
        analysis_date: Time.current
      }
    rescue => e
      Rails.logger.error "Error fetching company context: #{e.message}"
      {}
    end
  end
  
  def analyze_industry_trends(company_name, position)
    begin
      industry = detect_industry(company_name)
      
      prompt = <<~PROMPT
        #{industry} 산업의 2025년 현재 트렌드와 #{position} 직무 수요를 분석하세요:
        
        1. 산업 핵심 트렌드 (기술, 규제, 시장)
        2. 인재 수급 현황
        3. 필수 역량의 변화
        4. 향후 3년 전망
        5. 신입/경력 선호도
      PROMPT
      
      response = @parallel_service.call_api(prompt, temperature: 0.4)
      
      {
        industry: industry,
        trends: response[:content],
        position_demand: extract_position_demand(response[:content])
      }
    rescue => e
      Rails.logger.error "Error analyzing industry trends: #{e.message}"
      {}
    end
  end
  
  def analyze_competitor_hiring(company_name)
    competitors = identify_competitors(company_name)
    
    {
      competitors: competitors,
      hiring_comparison: compare_hiring_trends(competitors),
      talent_war_level: assess_talent_competition(company_name, competitors)
    }
  end
  
  def check_if_large_company(company_name)
    # 대기업 리스트 (확장 가능)
    large_companies = [
      '삼성', 'Samsung', '현대', 'Hyundai', 'LG', 'SK', 
      '롯데', 'Lotte', '한화', 'Hanwha', 'GS', '포스코', 'POSCO',
      '카카오', 'Kakao', '네이버', 'Naver', '쿠팡', 'Coupang',
      'CJ', '두산', 'Doosan', '신세계', 'Shinsegae', 
      'KT', 'KB', '신한', 'Shinhan', '우리', 'Woori', '하나', 'Hana',
      '농협', 'NH', '기업은행', 'IBK', '국민은행',
      '현대자동차', '기아', 'Kia', '한국전력', 'KEPCO',
      '대한항공', 'Korean Air', '아시아나', 'Asiana'
    ]
    
    # 회사명에 대기업 키워드가 포함되어 있는지 확인
    normalized_name = company_name.downcase.gsub(/[\(\)\.주식회사㈜]/, '')
    
    large_companies.any? do |keyword|
      normalized_name.include?(keyword.downcase)
    end
  end
  
  def build_comprehensive_prompt(company_name, position, job_content, context, trends, competitors)
    <<~PROMPT
      당신은 채용 전략 전문가입니다. 다음 정보를 바탕으로 지원자에게 실질적이고 구체적인 인사이트를 제공하세요.

      ## 기업 정보
      - 기업명: #{company_name}
      - 모집 직무: #{position}
      
      ## 채용공고 내용
      #{job_content[0..2000]}
      
      ## 기업 최신 맥락
      #{context && context[:recent_issues] ? context[:recent_issues].join("\n") : "정보 없음"}
      
      ## 산업 동향
      #{trends && trends[:trends] ? trends[:trends] : "정보 수집 중"}
      
      ## 경쟁사 동향
      #{competitors && competitors[:hiring_comparison] ? competitors[:hiring_comparison] : "분석 중"}
      
      다음 관점에서 종합 분석을 제공하세요:
      1. 왜 지금 이 시점에 채용하는가?
      2. 숨겨진 요구사항은 무엇인가?
      3. 지원자가 강조해야 할 핵심 포인트
      4. 차별화 전략
      5. 주의사항
      
      구체적이고 실용적인 조언을 4000자 이상으로 작성하세요.
    PROMPT
  end
  
  def generate_comprehensive_analysis(company_name, position, job_content, context, trends, competitors)
    prompt = build_comprehensive_prompt(company_name, position, job_content, context, trends, competitors)
    
    response = @parallel_service.call_api(
      prompt,
      system_prompt: '당신은 채용 전략 전문가이자 자소서 컨설턴트입니다. 지원자에게 실질적이고 구체적인 인사이트를 제공하세요.',
      temperature: 0.6,
      max_tokens: 3000  # 4000에서 3000으로 최적화
    )
    
    analysis = response[:content]
    
    # 구조화된 결과 생성
    {
      # 기본 정보
      company_name: company_name,
      position: position,
      analysis_date: Time.current,
      
      # 맥락 기반 분석
      company_context: {
        current_issues: context[:recent_issues] || [],
        urgent_needs: extract_urgent_needs(context, job_content),
        hidden_requirements: discover_hidden_requirements(context, job_content)
      },
      
      # 자소서 전략 (대폭 강화)
      cover_letter_strategy: generate_detailed_strategy(company_name, position, context, trends, competitors),
      
      # 차별화 포인트 (구체적 예시 포함)
      differentiation_guide: create_differentiation_guide(company_name, position, context, competitors),
      
      # 커스터마이징 가이드 (실전 예문 포함)
      customization_guide: create_detailed_customization_guide(company_name, position, context, trends),
      
      # 면접 대비 인사이트
      interview_insights: generate_interview_insights(context, trends),
      
      # 리스크 및 주의사항
      risks_and_warnings: identify_risks_and_warnings(context, competitors)
    }
  end
  
  def generate_detailed_strategy(company_name, position, context, trends, competitors)
    # context와 trends가 nil이거나 비어있을 때 처리
    context ||= {}
    trends ||= {}
    competitors ||= {}
    recent_issues = context[:recent_issues] || ["기업 정보 수집 중"]
    
    <<~STRATEGY
    ## 📋 자소서 작성 전략 완벽 가이드
    
    ### 1️⃣ 핵심 메시지 전략 (Core Message Strategy)
    
    #### A. 시의성 기반 접근 (왜 지금인가?)
    #{recent_issues.map { |issue| "• #{issue}" }.join("\n")}
    
    **활용 예시:**
    "#{company_name}이 #{recent_issues.first}하는 현 시점에, 제가 보유한 [구체적 역량]이 
    즉각적인 성과 창출에 기여할 수 있습니다. 특히 [관련 프로젝트 경험]을 통해 입증된 
    [핵심 역량]은 귀사가 직면한 [구체적 과제] 해결의 열쇠가 될 것입니다."
    
    #### B. 역량 증명 전략 (무엇을 할 수 있는가?)
    **필수 역량 매칭표:**
    | 기업 요구사항 | 내 역량 증명 | 구체적 증거 |
    |-------------|------------|----------|
    | #{extract_requirements(position)} | [여기에 본인 역량] | [프로젝트/성과 수치] |
    
    **작성 템플릿:**
    "#{position} 직무의 핵심인 [요구 역량]에 대해, 저는 [구체적 경험]을 통해
    [정량적 성과: 숫자로 표현]를 달성했습니다. 이 과정에서 [배운 점]을 체득했고,
    이는 #{company_name}의 [관련 업무]에 즉시 적용 가능합니다."
    
    ### 2️⃣ 강조 포인트 우선순위 (Priority Points)
    
    #### 최우선 강조 사항 (반드시 포함)
    1. **#{identify_top_priority(company_name, context)}**
       - 이유: #{explain_priority_reason(context)}
       - 표현 예시: "#{generate_expression_example(company_name)}"
    
    2. **#{position} 관련 실무 경험**
       - 인턴십, 프로젝트, 공모전 등 실제 경험 중심
       - STAR 기법: Situation(상황) → Task(과제) → Action(행동) → Result(결과)
       - 예시: "○○ 프로젝트에서 [상황], [과제]를 맡아, [구체적 행동]으로 [측정 가능한 결과] 달성"
    
    3. **#{company_name}만의 차별점과 연결**
       - #{identify_company_uniqueness(company_name)}
       - "귀사의 [독특한 강점]에 매력을 느꼈고, 제 [관련 경험]이 시너지를 낼 것입니다"
    
    #### 차순위 강조 사항 (선택적 포함)
    4. **성장 잠재력과 학습 능력**
       - 새로운 기술/지식 습득 사례
       - 실패를 통한 성장 스토리
    
    5. **팀워크와 소통 능력**
       - 갈등 해결, 협업 성과 사례
       - 다양한 이해관계자와의 소통 경험
    
    ### 3️⃣ 산업 트렌드 반영 전략
    
    **#{trends[:industry]} 산업 2025년 핵심 트렌드:**
    #{trends[:trends]}
    
    **자소서 반영 방법:**
    "#{trends[:industry]} 산업의 [핵심 트렌드]를 이해하고 있으며, 
    특히 [트렌드 관련 학습/프로젝트]를 통해 준비해왔습니다.
    #{company_name}이 [트렌드 대응 전략]을 추진하는 데 있어,
    제가 [구체적 기여 방안]으로 동참하고 싶습니다."
    
    ### 4️⃣ 경쟁사 대비 차별화 전략
    
    **경쟁 강도:** #{competitors[:talent_war_level]}/10
    **차별화 필수도:** #{calculate_differentiation_need(competitors)}
    
    **차별화 전술:**
    • 경쟁사와 다른 #{company_name}만의 가치 강조
    • 남들이 놓치는 #{identify_overlooked_points(company_name)}
    • 독특한 경험/관점으로 차별화
    
    STRATEGY
  end
  
  def create_differentiation_guide(company_name, position, context, competitors)
    <<~GUIDE
    ## 🎯 차별화 전략 실전 가이드
    
    ### 1. 시점 차별화 (Timing Differentiation)
    **현재 #{company_name}의 긴급 이슈:**
    #{(context[:recent_issues] || []).first(3).map { |i| "• #{i}" }.join("\n")}
    
    **차별화 작성법:**
    ```
    [일반적인 접근] ❌
    "귀사에 입사하여 열심히 배우고 성장하겠습니다."
    
    [시점 차별화 접근] ✅
    "#{company_name}이 #{(context[:recent_issues] || ["신규 프로젝트"]).first} 추진하는 2025년 8월,
    제가 [관련 분야]에서 축적한 [구체적 경험]이 프로젝트 초기 리스크를
    최소화하는 데 결정적 역할을 할 것입니다."
    ```
    
    ### 2. 경험 차별화 (Experience Differentiation)
    **#{position} 지원자 90%가 쓰는 진부한 표현:**
    • "소통을 잘합니다" → ❌
    • "책임감이 강합니다" → ❌
    • "성실합니다" → ❌
    
    **Top 10% 차별화 표현:**
    • "A/B 테스트로 전환율 23% 개선" → ✅
    • "크로스펑셔널 팀에서 PM 역할 수행" → ✅
    • "3개월 만에 신규 스킬 습득 후 실무 적용" → ✅
    
    ### 3. 인사이트 차별화 (Insight Differentiation)
    **#{company_name}에 대한 깊은 이해 보여주기:**
    
    **레벨 1 (평범):** "#{company_name}은 업계 선도기업입니다"
    **레벨 2 (양호):** "#{company_name}의 #{extract_key_product(company_name)}이 인상적입니다"
    **레벨 3 (우수):** "#{company_name}이 최근 발표한 #{(context[:recent_issues] || ["전략"]).first}는 
                      업계의 #{analyze_industry_impact(context)}을 보여줍니다"
    **레벨 4 (차별화):** "#{(context[:recent_issues] || ["새로운 비전"]).first}를 통해 #{company_name}이 추구하는
                        #{infer_strategic_direction(context)}에 제 #{position} 역량이
                        [구체적 기여 방안]으로 연결됩니다"
    
    ### 4. 스토리텔링 차별화
    **독특한 나만의 스토리 발굴법:**
    
    #### A. 실패 → 성장 스토리
    "○○ 프로젝트 실패 → 원인 분석 → 개선 → 재도전 성공"
    
    #### B. 융합형 경험 스토리
    "전공(A) + 부전공(B) + 대외활동(C) = 독특한 시너지"
    
    #### C. 사회적 가치 스토리
    "기술력 + 사회 문제 해결 = #{company_name} ESG 전략과 연결"
    
    ### 5. 숫자로 말하는 차별화
    **정량화 체크리스트:**
    □ 프로젝트 규모 (예산, 기간, 인원)
    □ 성과 지표 (개선율, 절감액, 효율성)
    □ 영향 범위 (수혜자 수, 적용 범위)
    □ 학습 속도 (습득 기간, 적용 시점)
    □ 지속 기간 (프로젝트 기간, 효과 지속성)
    
    GUIDE
  end
  
  def create_detailed_customization_guide(company_name, position, context, trends)
    <<~CUSTOM
    ## 📝 자소서 커스터마이징 완벽 가이드
    
    ### 1. 지원동기 작성법 (1000자 기준)
    
    #### 구조 설계 (황금 비율)
    • 도입 (15%): 시선을 끄는 첫 문장
    • 기업 이해 (25%): #{company_name} 핵심 가치와 비전
    • 개인 연결 (35%): 나의 경험과 기업 니즈 매칭
    • 미래 비전 (20%): 함께 만들 미래
    • 마무리 (5%): 강력한 의지 표현
    
    #### 도입부 작성 예시 (3가지 스타일)
    
    **A. 시사 이슈 활용형**
    "#{(context[:recent_issues] || ["혁신 전략"]).first}을 발표한 #{company_name}의 도전적 행보를 보며,
    저 역시 이 혁신의 여정에 동참하고 싶다는 강한 열망을 느꼈습니다."
    
    **B. 개인 경험 스토리형**
    "[개인적 경험/계기]를 통해 #{position} 분야에 매력을 느낀 이후,
    #{company_name}이야말로 제 역량을 가장 잘 발휘할 수 있는 곳임을 확신했습니다."
    
    **C. 미래 비전 제시형**
    "#{trends[:industry]} 산업이 [미래 변화]를 맞이하는 시점에서,
    #{company_name}과 함께 [구체적 미래상]을 만들어가고 싶습니다."
    
    #### 기업 이해 표현법
    
    **표면적 이해 (지양):**
    "#{company_name}은 #{trends[:industry]} 업계 1위 기업입니다"
    
    **심층적 이해 (지향):**
    "#{company_name}이 #{(context[:recent_issues] || ["미래 전략"]).first}를 통해 추구하는 
    [전략적 방향]은 단순한 사업 확장을 넘어 [산업 패러다임 전환]을 
    선도하는 비전이라고 이해했습니다. 특히 [구체적 사례]를 보며..."
    
    ### 2. 경험 기술 고급 테크닉
    
    #### STAR+ 기법 (STAR + Learning)
    **S** ituation: "○○ 상황에서"
    **T** ask: "○○ 과제를 맡았고"
    **A** ction: "○○ 방법으로 접근하여"
    **R** esult: "○○ 성과를 달성했으며"
    **+L** earning: "이를 통해 ○○를 배웠습니다"
    
    #### 경험 기술 템플릿
    
    **[프로젝트 경험]**
    "#{position} 직무와 직결되는 ○○ 프로젝트에서 [역할]을 맡아,
    [구체적 문제 상황]에 직면했습니다. 저는 [창의적 해결 방법]을 제안하고
    [실행 과정]을 거쳐 [정량적 성과]를 달성했습니다.
    특히 이 과정에서 [핵심 깨달음]을 얻었고, 이는 #{company_name}의
    [관련 업무]에서 [구체적 활용 방안]으로 적용할 수 있습니다."
    
    **[인턴십 경험]**
    "○○사 인턴십에서 [부서/팀]의 [구체적 업무]를 수행하며,
    [현장의 실제 문제]를 경험했습니다. [시행착오]를 겪으며
    [실무 역량]을 체득했고, 최종적으로 [가시적 기여]를 인정받아
    [평가/피드백]을 받았습니다. 이 경험은 #{company_name}에서
    [즉시 활용 가능한 역량]으로 작용할 것입니다."
    
    ### 3. 입사 후 포부 로드맵
    
    #### 시간대별 구체적 목표 설정
    
    **[입사~3개월: 적응기]**
    • #{company_name}의 업무 프로세스와 조직문화 체득
    • #{position} 직무 기본 역량 확보
    • 팀 내 역할 정립과 신뢰 구축
    
    **[3개월~1년: 성장기]**
    • 독립적 업무 수행 능력 확보
    • [구체적 프로젝트/업무] 참여 및 기여
    • [관련 자격증/스킬] 추가 습득
    
    **[1~3년: 기여기]**
    • #{position} 분야 전문성 확립
    • 신규 프로젝트 리드 또는 핵심 참여
    • 후배 멘토링 및 팀 시너지 창출
    
    **[3~5년: 도약기]**
    • #{company_name}의 [핵심 사업] 성장 주도
    • [더 큰 책임/역할] 수행
    • 업계 전문가로서의 위상 확립
    
    **[5년 이후: 비전]**
    "#{company_name}의 #{infer_future_direction(context, trends)}을 이끄는
    핵심 인재로 성장하여, [구체적 비전] 실현에 기여하겠습니다."
    
    ### 4. 문항별 차별화 작성법
    
    #### "실패/어려움 극복 경험" 문항
    **[구조]**
    1. 도전적 상황 설정 (20%)
    2. 실패의 구체적 묘사 (20%)
    3. 원인 분석과 성찰 (25%)
    4. 개선 행동과 재도전 (25%)
    5. 결과와 교훈 (10%)
    
    **[차별화 포인트]**
    • 실패를 인정하는 솔직함
    • 체계적 원인 분석 능력
    • 회복탄력성과 끈기
    • 학습과 성장 마인드셋
    
    #### "팀워크/협업 경험" 문항
    **[필수 요소]**
    • 팀 규모와 구성
    • 본인의 명확한 역할
    • 갈등이나 어려움 상황
    • 소통과 조율 과정
    • 시너지 창출 결과
    
    ### 5. 마지막 체크리스트
    
    □ #{company_name} 최신 이슈 반영했는가?
    □ #{position} 핵심 역량 증명했는가?
    □ 정량적 성과를 포함했는가?
    □ 차별화된 스토리가 있는가?
    □ 미래 기여 방안이 구체적인가?
    □ 진정성이 느껴지는가?
    □ 오타나 문법 오류는 없는가?
    
    CUSTOM
  end
  
  def generate_interview_insights(context, trends)
    <<~INTERVIEW
    ## 💼 예상 면접 질문 및 대비 전략
    
    ### 맥락 기반 예상 질문
    1. "#{(context[:recent_issues] || ["최근 발표"]).first}에 대해 어떻게 생각하시나요?"
    2. "우리 회사가 왜 지금 #{extract_position_from_context(context)}를 채용한다고 생각하시나요?"
    3. "#{trends[:industry]} 산업의 향후 전망을 어떻게 보시나요?"
    
    ### 답변 준비 가이드
    • 기업 이슈에 대한 본인만의 관점 정리
    • 구체적 기여 방안 준비
    • 산업 트렌드와 개인 역량 연결
    
    INTERVIEW
  end
  
  def identify_risks_and_warnings(context, competitors)
    <<~RISKS
    ## ⚠️ 주의사항 및 리스크
    
    ### 회피해야 할 표현
    • 과도한 아부나 칭찬
    • 검증 불가능한 과장
    • 타사 비방이나 비교
    • 민감한 이슈 언급
    
    ### 경쟁 강도 평가
    • 경쟁률 예상: #{estimate_competition_rate(competitors)}
    • 차별화 필수도: #{competitors[:talent_war_level]}/10
    • 특별히 주의할 점: #{identify_special_concerns(context)}
    
    RISKS
  end
  
  # Helper methods
  def search_recent_news(company_name)
    # 실제 뉴스 검색 로직
    company = Company.find_or_create_by(name: company_name)
    crawler = CompanyNewsCrawlerService.new(company)
    news = crawler.crawl_all_sources
    
    news.first(10).map do |item|
      {
        title: item[:title],
        date: item[:published_at],
        source: item[:source],
        summary: item[:summary]
      }
    end
  rescue => e
    Rails.logger.error "News search failed: #{e.message}"
    []
  end
  
  def detect_industry(company_name)
    # 기업명으로 산업 추론
    case company_name.downcase
    when /약품|제약|바이오|pharm/
      "제약/바이오"
    when /전자|반도체|디스플레이/
      "전자/반도체"
    when /자동차|모빌리티/
      "자동차/모빌리티"
    when /금융|은행|보험|증권/
      "금융"
    when /건설|건축|엔지니어링/
      "건설/엔지니어링"
    else
      "일반"
    end
  end
  
  def identify_competitors(company_name)
    # 경쟁사 식별 로직
    case company_name
    when "한미약품"
      ["유한양행", "대웅제약", "종근당", "녹십자"]
    when "삼성전자"
      ["LG전자", "SK하이닉스", "애플", "화웨이"]
    when "SK이노베이션"
      ["LG화학", "롯데케미칼", "한화솔루션"]
    else
      []
    end
  end
  
  def parse_company_issues(content)
    return [] unless content
    
    # AI 응답에서 핵심 이슈 추출
    issues = content.scan(/\d+\.\s*(.+)/).flatten
    issues.first(5)
  end
  
  def extract_requirements(position)
    # 직무별 일반적 요구사항
    case position.downcase
    when /개발|엔지니어|프로그래/
      "프로그래밍 능력, 문제해결력, 기술 트렌드 이해"
    when /마케팅|홍보/
      "시장 분석, 크리에이티브, 데이터 분석"
    when /영업|세일즈/
      "고객 지향, 협상력, 목표 달성 의지"
    when /인사|hr/
      "조직 이해, 소통 능력, 공정성"
    else
      "직무 전문성, 팀워크, 성장 의지"
    end
  end
  
  def identify_top_priority(company_name, context)
    # 기업별 최우선 강조사항 판단
    if (context[:recent_issues] || []).any? { |i| i.include?("글로벌") }
      "글로벌 역량과 다문화 경험"
    elsif (context[:recent_issues] || []).any? { |i| i.include?("디지털") }
      "디지털 전환 관련 역량"
    elsif (context[:recent_issues] || []).any? { |i| i.include?("ESG") }
      "지속가능성과 사회적 가치"
    else
      "직무 전문성과 즉시 기여 가능성"
    end
  end
  
  def explain_priority_reason(context)
    "최근 기업이 집중하는 #{(context[:recent_issues] || ["핵심 과제"]).first}와 직결되기 때문"
  end
  
  def generate_expression_example(company_name)
    "#{company_name}의 [핵심 가치]에 깊이 공감하며, 제 [관련 경험]을 통해 [구체적 기여]하겠습니다"
  end
  
  def identify_company_uniqueness(company_name)
    # 기업별 고유 강점 (실제로는 DB화 필요)
    "업계 최고 수준의 기술력과 조직문화"
  end
  
  def extract_position_demand(content)
    # AI 응답에서 직무 수요 추출
    "높음"  # 실제 로직 구현 필요
  end
  
  def compare_hiring_trends(competitors)
    # 경쟁사 채용 동향 비교
    "활발"  # 실제 로직 구현 필요
  end
  
  def assess_talent_competition(company_name, competitors)
    # 인재 경쟁 강도 평가 (1-10)
    7  # 실제 로직 구현 필요
  end
  
  def extract_urgent_needs(context, job_content)
    # 긴급 니즈 추출
    []
  end
  
  def discover_hidden_requirements(context, job_content)
    # 숨은 요구사항 발견
    []
  end
  
  def calculate_differentiation_need(competitors)
    # 차별화 필요도
    "매우 높음"
  end
  
  def identify_overlooked_points(company_name)
    # 놓치기 쉬운 포인트
    "조직문화와 핵심 가치"
  end
  
  def infer_strategic_direction(context)
    # 전략 방향 추론
    "디지털 전환과 글로벌 확장"
  end
  
  def extract_key_product(company_name)
    # 주력 제품/서비스
    "핵심 제품/서비스"
  end
  
  def analyze_industry_impact(context)
    # 산업 영향 분석
    "패러다임 전환"
  end
  
  def infer_future_direction(context, trends)
    # 미래 방향 추론
    "차세대 시장 선도"
  end
  
  def extract_position_from_context(context)
    # 맥락에서 직무 추출
    "핵심 인재"
  end
  
  def estimate_competition_rate(competitors)
    # 경쟁률 추정
    "50:1 ~ 100:1"
  end
  
  def identify_special_concerns(context)
    # 특별 주의사항
    "기업 이슈에 대한 깊은 이해 필수"
  end
end