require 'net/http'
require 'json'

class EnhancedJobPostingAnalyzerService
  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    @model = ENV['OPENAI_MODEL'] || 'gpt-4o'
    @parallel_service = ParallelOpenaiService.new
  end
  
  def perform_deep_analysis(company_name, position, job_content, url = nil)
    Rails.logger.info "=== 강화된 채용공고 분석 시작 (6-way Parallel) ==="
    Rails.logger.info "Company: #{company_name}, Position: #{position}"
    
    # 6개 섹션을 완전 병렬로 처리
    futures = []
    errors = []
    
    # 1. 기업 개요 & 산업 포지션 분석
    futures << Concurrent::Future.execute do
      begin
        analyze_company_overview_section(company_name, position, job_content)
      rescue => e
        Rails.logger.error "Company Overview Error: #{e.message}"
        errors << "Company Overview: #{e.message}"
        nil
      end
    end
    
    # 2. 채용공고 기본 정보 & 맥락 분석
    futures << Concurrent::Future.execute do
      begin
        analyze_job_context_section(company_name, position, job_content)
      rescue => e
        Rails.logger.error "Job Context Error: #{e.message}"
        errors << "Job Context: #{e.message}"
        nil
      end
    end
    
    # 3. 직무 분석 & 요구 역량 (핵심, 2000자+)
    futures << Concurrent::Future.execute do
      begin
        analyze_job_requirements_section(company_name, position, job_content)
      rescue => e
        Rails.logger.error "Job Requirements Error: #{e.message}"
        errors << "Job Requirements: #{e.message}"
        nil
      end
    end
    
    # 4. 취업 준비 전략 (자소서·면접)
    futures << Concurrent::Future.execute do
      begin
        analyze_preparation_strategy_section(company_name, position, job_content)
      rescue => e
        Rails.logger.error "Preparation Strategy Error: #{e.message}"
        errors << "Preparation Strategy: #{e.message}"
        nil
      end
    end
    
    # 5. 경쟁사 비교 & 차별화 전략
    futures << Concurrent::Future.execute do
      begin
        analyze_competition_section(company_name, position, job_content)
      rescue => e
        Rails.logger.error "Competition Analysis Error: #{e.message}"
        errors << "Competition Analysis: #{e.message}"
        nil
      end
    end
    
    # 6. 핵심 요약 & 컨설턴트 조언 (1500자+)
    futures << Concurrent::Future.execute do
      begin
        generate_consultant_summary_section(company_name, position, job_content)
      rescue => e
        Rails.logger.error "Consultant Summary Error: #{e.message}"
        errors << "Consultant Summary: #{e.message}"
        nil
      end
    end
    
    # 모든 Future 완료 대기 (타임아웃 30초)
    results = futures.map.with_index do |future, index|
      result = future.value(30)
      Rails.logger.info "Section #{index + 1} completed: #{result ? 'Success' : 'Failed'}"
      result
    end
    
    # 에러 로깅
    if errors.any?
      Rails.logger.error "Enhanced Analysis Errors: #{errors.join(', ')}"
    end
    
    # 결과 조합
    {
      # 기본 정보
      company_name: company_name,
      position: position,
      analysis_date: Time.current,
      
      # 6개 섹션 독립 분석 결과
      sections: {
        company_overview: results[0] || "분석 중 오류가 발생했습니다.",
        job_context: results[1] || "분석 중 오류가 발생했습니다.",
        job_requirements: results[2] || "분석 중 오류가 발생했습니다.",  # 핵심 2000자+
        preparation_strategy: results[3] || "분석 중 오류가 발생했습니다.",
        competition_analysis: results[4] || "분석 중 오류가 발생했습니다.",
        consultant_summary: results[5] || "분석 중 오류가 발생했습니다."  # 1500자+
      },
      
      # 메타데이터
      metadata: {
        analysis_version: 'enhanced_v3.0_parallel',
        total_sections: 6,
        successful_sections: results.compact.count,
        parallel_threads: 6,
        errors: errors,
        model_used: @model || 'gpt-4.1'
      }
    }
  end
  
  private
  
  # 섹션 1: 기업 개요 & 산업 포지션
  def analyze_company_overview_section(company_name, position, job_content)
    prompt = <<~PROMPT
      채용공고 분석 - 섹션 1: 기업 개요 & 산업 포지션
      
      기업명: #{company_name}
      직무: #{position}
      현재 날짜: #{Time.current.strftime('%Y년 %m월')}
      
      채용공고 내용:
      #{job_content[0..1500]}
      
      다음 내용을 800자 이상으로 분석하세요:
      
      ## 1. 기업 개요 & 산업 포지션
      
      - 기업 연혁과 핵심 비즈니스 모델
      - 최근 3년 매출 구조와 성장 추이
      - 최근 전략 변화 (AI, 글로벌 확장, M&A 등)
      - 산업 내 위치 (경쟁사 대비 강점/약점)
      - 최근 이슈사항 (2025년 기준)
      
      [취업 TIP]을 반드시 포함하고, 실제 채용공고 문구를 인용하며 분석하세요.
    PROMPT
    
    response = @parallel_service.call_api(
      prompt,
      system_prompt: '채용공고 분석 전문가로서 기업과 산업 맥락을 상세히 분석하세요.',
      temperature: 0.7,
      max_tokens: 1500
    )
    
    response[:content] || "기업 개요 분석 실패"
  end
  
  # 섹션 2: 채용공고 기본 정보 & 맥락
  def analyze_job_context_section(company_name, position, job_content)
    prompt = <<~PROMPT
      채용공고 분석 - 섹션 2: 채용공고 기본 정보 & 맥락
      
      기업명: #{company_name}
      직무: #{position}
      현재 날짜: #{Time.current.strftime('%Y년 %m월')}
      
      채용공고 내용:
      #{job_content[0..2000]}
      
      다음 내용을 800자 이상으로 분석하세요:
      
      ## 2. 채용공고 기본 정보 & 맥락
      
      - 모집 직무명, 고용형태, 근무지, 자격요건, 우대사항 정리
      - "왜 지금 이 직무를 채용하는가?"를 산업·기업 맥락과 연결
      - 채용공고에 숨겨진 의도와 니즈 파악
      - 긴급도와 중요도 평가
      
      반드시 Why-So What-How 3단계 구조로 설명하고 [취업 TIP]을 포함하세요.
    PROMPT
    
    response = @parallel_service.call_api(
      prompt,
      system_prompt: '채용공고의 숨은 의도와 맥락을 날카롭게 분석하세요.',
      temperature: 0.7,
      max_tokens: 1500
    )
    
    response[:content] || "채용 맥락 분석 실패"
  end
  
  # 섹션 3: 직무 분석 & 요구 역량 (핵심, 2000자+)
  def analyze_job_requirements_section(company_name, position, job_content)
    prompt = <<~PROMPT
      채용공고 분석 - 섹션 3: 직무 분석 & 요구 역량 (핵심 파트)
      
      기업명: #{company_name}
      직무: #{position}
      현재 날짜: #{Time.current.strftime('%Y년 %m월')}
      
      채용공고 전문:
      #{job_content[0..3000]}
      
      다음 내용을 반드시 2,000자 이상으로 초상세하게 분석하세요:
      
      ## 3. 직무 분석 & 요구 역량 (핵심 파트, 최소 2,000자)
      
      ### 3-1. 채용 방식 분석
      - 정기공채 vs 수시 vs 프로젝트형 채용의 의미
      - 지원자에게 미치는 영향
      
      ### 3-2. 채용공고 키워드별 요구 역량 심층 분석
      채용공고의 실제 문구를 "" 안에 인용하며:
      - 필수 역량: Why(왜 필요한가) → So What(지원자 의미) → How(준비 방법)
      - 우대 역량: Why → So What → How
      - 숨겨진 역량: 명시되지 않았지만 필요한 것들
      
      ### 3-3. 인재상 분석
      - 기업 공식 인재상
      - 실제 현업에서 중시되는 특성
      - 지원자가 보여줘야 할 포인트
      
      각 키워드마다 Why-So What-How 구조로 상세히 설명하고,
      실제 활용 가능한 예문을 포함한 [취업 TIP]을 3개 이상 넣으세요.
    PROMPT
    
    response = @parallel_service.call_api(
      prompt,
      system_prompt: '채용공고 분석 전문가로서 요구 역량을 초디테일하게 분석하세요. 반드시 2000자 이상 작성하세요.',
      temperature: 0.7,
      max_tokens: 2500
    )
    
    response[:content] || "직무 요구사항 분석 실패"
  end
  
  # 섹션 4: 취업 준비 전략 (자소서·면접)
  def analyze_preparation_strategy_section(company_name, position, job_content)
    prompt = <<~PROMPT
      채용공고 분석 - 섹션 4: 취업 준비 전략
      
      기업명: #{company_name}
      직무: #{position}
      
      채용공고 핵심:
      #{job_content[0..1500]}
      
      다음 내용을 1,200자 이상으로 분석하세요:
      
      ## 4. 취업 준비 전략 (자소서·면접 연결)
      
      ### 자소서 작성 전략
      - 강조해야 할 핵심 포인트 3가지
      - STAR+ 기법 활용 예시
      - 실제 작성 템플릿과 예문
      
      ### 면접 대비 전략
      - 예상 질문 Top 5와 모범 답변 구조
      - 포트폴리오 구성 방향
      - 차별화 포인트
      
      ### 준비 체크리스트
      - 지금 당장 해야 할 3가지
      - 1개월 준비 계획
      
      실제 활용 가능한 예문과 템플릿을 포함한 [취업 TIP]을 제공하세요.
    PROMPT
    
    response = @parallel_service.call_api(
      prompt,
      system_prompt: '실용적이고 구체적인 취업 준비 전략을 제시하세요.',
      temperature: 0.7,
      max_tokens: 2000
    )
    
    response[:content] || "준비 전략 분석 실패"
  end
  
  # 섹션 5: 경쟁사 비교 & 차별화 전략
  def analyze_competition_section(company_name, position, job_content)
    prompt = <<~PROMPT
      채용공고 분석 - 섹션 5: 경쟁사 비교 & 차별화 전략
      
      기업명: #{company_name}
      직무: #{position}
      
      다음 내용을 1,000자 이상으로 분석하세요:
      
      ## 5. 경쟁사 비교 & 차별화 전략
      
      ### 동종업계 채용 트렌드
      - 주요 경쟁사 채용 동향
      - 업계 표준 vs #{company_name}만의 특징
      
      ### 지원자 차별화 전략
      - 90%가 하는 실수 vs Top 10% 전략
      - #{company_name}만을 위한 맞춤 어필 포인트
      - 경쟁률 예상과 대응 방법
      
      ### 포지셔닝 전략
      - 나만의 독특한 강점 찾기
      - 스토리텔링으로 차별화하기
      
      구체적인 차별화 예시와 [취업 TIP]을 포함하세요.
    PROMPT
    
    response = @parallel_service.call_api(
      prompt,
      system_prompt: '경쟁 환경과 차별화 전략을 날카롭게 분석하세요.',
      temperature: 0.7,
      max_tokens: 1500
    )
    
    response[:content] || "경쟁 분석 실패"
  end
  
  # 섹션 6: 핵심 요약 & 컨설턴트 조언 (1500자+)
  def generate_consultant_summary_section(company_name, position, job_content)
    prompt = <<~PROMPT
      채용공고 분석 - 섹션 6: 핵심 요약 & 컨설턴트 조언
      
      기업명: #{company_name}
      직무: #{position}
      
      반드시 1,500자 이상으로 작성하세요:
      
      ## 6. 핵심 요약 & 컨설턴트 조언 (심층, 최소 1,500자)
      
      ### 🎯 취업 준비생이 반드시 기억해야 할 핵심 5가지
      
      1. [가장 중요한 포인트]
         - 왜 중요한가: [상세 설명]
         - 어떻게 준비하나: [구체적 방법]
         - 자소서 활용: [실제 예문]
         - 면접 활용: [답변 예시]
      
      2~5. [동일 구조로 작성]
      
      ### 📋 합격률을 높이기 위해 지금 당장 해야 할 3가지 행동
      
      1. [오늘 시작]: [구체적 행동과 방법]
      2. [이번 주 완료]: [구체적 목표와 계획]
      3. [이번 달 달성]: [측정 가능한 성과]
      
      ### 💡 최종 메시지
      #{company_name} #{position} 합격을 위한 핵심 전략과 
      차별화 포인트를 종합하여 강력한 동기부여 메시지 제공
      
      반드시 1,500자 이상의 깊이 있는 조언을 작성하세요.
    PROMPT
    
    response = @parallel_service.call_api(
      prompt,
      system_prompt: '15년 경력 컨설턴트로서 심층적이고 실용적인 조언을 1,500자 이상 제공하세요.',
      temperature: 0.7,
      max_tokens: 2000
    )
    
    response[:content] || "컨설턴트 조언 생성 실패"
  end
  
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
      📌 최종 강화 프롬프트 (채용공고 분석 / 초디테일 버전)
      너는 [채용공고 분석 전문가이자 취업컨설턴트] 역할을 맡는다.  
      너의 임무는 특정 채용공고를 분석하여 취업 준비생이 자기소개서, 면접, 포트폴리오, 커리어 전략에 바로 활용할 수 있는 **초디테일 심층 채용공고 분석 리포트(최소 4,500자)**를 작성하는 것이다.  

      ## 🎯 채용공고 정보
      - 기업명: #{company_name}
      - 모집 직무: #{position}
      - 현재 날짜: #{Time.current.strftime('%Y년 %m월')}
      
      ## 📝 채용공고 원문
      #{job_content[0..3000]}
      
      ## 🔍 기업 최신 맥락 (2025년)
      #{context && context[:recent_issues] ? context[:recent_issues].map { |i| "• #{i}" }.join("\n") : "• 정보 수집 중"}
      
      ## 📊 산업 동향 분석
      #{trends && trends[:trends] ? trends[:trends] : "정보 수집 중"}
      
      ## 🏢 경쟁사 채용 동향
      #{competitors && competitors[:hiring_comparison] ? competitors[:hiring_comparison] : "분석 중"}

      ### 작성 원칙
      1. 각 항목은 반드시 **실제 채용공고 문구(Keywords)**를 인용하고,  
         → (예: "SQL 활용 능력", "대규모 트래픽 환경 경험")  
         → 이 문구가 "왜 중요한지"를 **산업/기업 맥락**에서 해석하고,  
         → "구직자가 어떻게 활용할 수 있는지"를 **자소서·면접·포트폴리오 적용법**까지 구체적으로 제시한다.  

      2. 단순한 요구사항 나열이 아니라:  
         - **Why? (기업이 왜 이 역량을 찾는가)**  
         - **So what? (지원자에게 어떤 의미가 있는가)**  
         - **How? (지원자가 어떻게 준비하고 보여줄 수 있는가)**  
         의 3단계 구조로 설명한다.  

      3. 각 섹션 끝에는 **[취업 TIP]** 박스를 넣어, 구체적 행동 가이드를 정리한다.  

      4. [3. 직무 분석 & 요구 역량]은 최소 2,000자 이상,  
         [6. 핵심 요약 & 컨설턴트 조언]은 최소 1,500자 이상으로 작성한다.  

      5. [6. 핵심 요약 & 컨설턴트 조언]에서는:  
         - 취업 준비생이 반드시 기억해야 할 핵심 5가지  
         - 각 항목의 중요성과 실제 준비 방법 (자소서, 포트폴리오, 면접 전략)  
         - "합격률을 높이기 위해 구직자가 지금 당장 해야 할 3가지 행동"  
         을 구체적으로 제시한다.  

      6. 전체 글은 전문 컨설팅 보고서 스타일로 작성하며, 최소 4,500자 이상 분량을 유지한다.  

      ---

      ## 📍 분석 프레임워크

      1. **기업 개요 & 산업 포지션**  
         - 기업 연혁, 핵심 비즈니스 모델, 최근 3년 매출 구조  
         - 최근 전략 변화 (AI, 글로벌 확장, M&A 등)  
         - 산업 내 위치 (경쟁사 대비 강점/약점)  
         - 최근 이슈사항 (뉴스·기사 기반)

      2. **채용공고 기본 정보 & 맥락**  
         - 모집 기업, 직무명, 고용형태, 근무지, 자격요건, 우대사항  
         - "왜 지금 이 직무를 채용하는가?"를 산업·기업 맥락과 연결하여 설명  

      3. **직무 분석 & 요구 역량 (핵심 파트, 최소 2,000자)**  
         - 3-1. 채용 방식 분석 (정기공채 vs 수시 vs 프로젝트형) → 지원자에게 의미  
         - 3-2. 채용공고 키워드별 요구 역량 심층 분석  
           * 개발직군: 기술스택, 프로젝트 경험, 대규모 트래픽 경험  
           * 기획/PM: 데이터 기반 기획, 사용자 경험, 시장분석 역량  
           * 데이터/AI: 머신러닝·딥러닝, 추천 알고리즘, MLOps  
           * 디자인: UX/UI 개선, BX, 글로벌 감각  
           - 각 키워드별로 Why–So What–How 구조로 상세히 풀어낼 것  
         - 3-3. 인재상 분석  
           - 기업 공식 인재상 + 실제 현업에서 암묵적으로 중시되는 특성  

      4. **취업 준비 전략 (자소서·면접 연결)**  
         - 자소서 작성 시 강조 포인트 (직무별 맞춤 사례 포함)  
         - STAR+ 기법 활용한 경험 기술법  
         - 면접 예상 질문과 답변 전략  
         - 포트폴리오 구성 전략  

      5. **경쟁사 비교 & 차별화 전략**  
         - 동종업계 채용 트렌드와 비교  
         - #{company_name}만의 특징과 지원자 차별화 포인트  
         - 경쟁률 예상과 대응 전략  

      6. **핵심 요약 & 컨설턴트 조언 (심층, 최소 1,500자)**  
         - 취업 준비생이 반드시 기억해야 할 핵심 5가지  
         - 각 항목의 중요성과 실제 준비 방법  
         - 지금 당장 해야 할 3가지 행동  

      ---

      ## 📍 출력 형식
      - 마크다운 구조 (제목·소제목·리스트·표 적극 활용)  
      - 각 파트는 최소 5문단 이상  
      - [3. 직무 분석 & 요구 역량] 2,000자 이상 / [6. 핵심 요약] 1,500자 이상  
      - 최종 리포트는 최소 4,500자 이상  
      - 전문 컨설팅 보고서 스타일 (실제 리서치 기반, 실행 전략 중심)
      - 실제 채용공고 문구를 "" 안에 인용하며 분석
    PROMPT
  end
  
  def generate_comprehensive_analysis(company_name, position, job_content, context, trends, competitors)
    prompt = build_comprehensive_prompt(company_name, position, job_content, context, trends, competitors)
    
    response = @parallel_service.call_api(
      prompt,
      system_prompt: '당신은 15년 경력의 채용공고 분석 전문가이자 취업컨설턴트입니다. 
      취업 준비생에게 실질적이고 구체적인 인사이트를 제공하세요. 
      반드시 4,500자 이상의 초디테일 분석을 작성하고, 
      채용공고의 실제 문구를 인용하며 Why-So What-How 3단계 구조로 설명하세요.
      각 섹션마다 [취업 TIP]을 포함하고, 실제 활용 가능한 예문과 템플릿을 제공하세요.',
      temperature: 0.7,
      max_tokens: 4000  # 초디테일 분석을 위해 증가
    )
    
    # API 응답을 메인 분석으로 사용
    main_analysis = response[:content] || "분석 중 오류가 발생했습니다."
    
    # 구조화된 결과 생성
    {
      # 기본 정보
      company_name: company_name,
      position: position,
      analysis_date: Time.current,
      
      # 초디테일 메인 분석 (프롬프트대로 생성된 4,500자 이상 분석)
      comprehensive_analysis: main_analysis,
      
      # 맥락 기반 추가 정보
      company_context: {
        current_issues: context[:recent_issues] || [],
        urgent_needs: extract_urgent_needs(context, job_content),
        hidden_requirements: discover_hidden_requirements(context, job_content)
      },
      
      # 보조 가이드 (메인 분석 보완용)
      supplementary_guides: {
        # 자소서 전략 (추가 템플릿)
        cover_letter_templates: generate_detailed_strategy(company_name, position, context, trends, competitors),
        
        # 차별화 가이드 (추가 예시)
        differentiation_examples: create_differentiation_guide(company_name, position, context, competitors),
        
        # 커스터마이징 가이드 (추가 예문)
        customization_samples: create_detailed_customization_guide(company_name, position, context, trends),
        
        # 면접 인사이트 (추가 질문)
        interview_questions: generate_interview_insights(context, trends),
        
        # 주의사항
        warnings: identify_risks_and_warnings(context, competitors)
      },
      
      # 메타데이터
      metadata: {
        analysis_version: 'enhanced_v2.0',
        word_count: main_analysis.length,
        includes_tips: main_analysis.include?('[취업 TIP]'),
        api_model: response[:model] || 'gpt-4.1'
      }
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