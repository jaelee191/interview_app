class ProfessionalCompanyAnalyzerService
  def initialize(company_name)
    @company_name = company_name
    @api_key = ENV['OPENAI_API_KEY']
  end

  def perform_professional_analysis
    {
      executive_summary: generate_executive_summary,
      company_overview: analyze_company_overview,
      industry_market_analysis: analyze_industry_market,
      financial_analysis: analyze_financials,
      strategic_direction: analyze_strategy,
      risk_factors: analyze_risks,
      future_outlook: generate_outlook,
      key_insights: generate_insights,
      metadata: {
        analysis_date: Time.current,
        analysis_version: '2.0',
        methodology: 'McKinsey/BCG Framework'
      }
    }
  end

  private

  def generate_executive_summary
    prompt = <<~PROMPT
      기업명: #{@company_name}
      현재 날짜: #{Time.current.strftime('%Y년 %m월')}
      
      **중요**: 2025년 8월 기준 가장 최신 정보를 반영하여 작성하세요. 2025년 상반기 실적, 최근 발표, 현재 진행 중인 프로젝트 등을 포함하세요.
      
      다음 형식으로 Executive Summary를 작성하세요:
      
      ## Executive Summary
      
      ### 핵심 요약 (3줄)
      • [2025년 현재 기업의 위치와 핵심 강점]
      • [2025년 당면한 주요 도전과제 및 기회]
      • [2025-2026년 전망과 핵심 제언]
      
      ### 투자 포인트 (2025년 기준)
      • 강점 1: [2025년 최신 데이터 기반 설명]
      • 강점 2: [구체적 설명]
      • 강점 3: [구체적 설명]
      
      ### 주요 리스크 (2025년 기준)
      • 리스크 1: [2025년 현재 상황 반영]
      • 리스크 2: [구체적 설명]
      
      ### 전략적 제언
      • 단기(2025년 하반기-2026년 상반기): [구체적 행동 방안]
      • 중기(2026-2028년): [전략적 방향성]
      
      2025년 최신 시장 상황과 기업 동향을 반영한 전문적이고 데이터 기반의 분석을 제공하세요.
    PROMPT

    call_gpt_api(prompt)
  end

  def analyze_company_overview
    prompt = <<~PROMPT
      기업명: #{@company_name}
      현재 날짜: 2025년 8월
      
      ## 1. 기업 개요 (2025년 8월 기준)
      
      ### 기업 정보
      • 설립연도: 
      • 본사 위치:
      • CEO/대표: [2025년 현재 경영진]
      • 임직원 수: [2025년 최신 데이터]
      • 주요 사업 부문:
      • 2025년 상반기 매출: [최신 실적]
      
      ### 비즈니스 모델
      • 핵심 가치 제안(Value Proposition):
      • 수익 창출 방식:
      • 주요 고객군:
      • 경쟁 우위:
      
      ### 시장 포지셔닝 (2025년 기준)
      • 시장 점유율: [2025년 최신 데이터]
      • 브랜드 파워:
      • 기술력 수준:
      • 고객 충성도:
      
      ### [핵심 요약 3줄]
      1. 
      2. 
      3. 
      
      2025년 8월 기준 최신 정보로 맥킨지 스타일의 구조화된 분석을 제공하세요.
    PROMPT

    call_gpt_api(prompt)
  end

  def analyze_industry_market
    prompt = <<~PROMPT
      기업명: #{@company_name}
      현재 날짜: 2025년 8월
      
      ## 2. 산업·시장 분석 (2025년 기준)
      
      ### 시장 규모 및 성장성 (2025년 전망)
      • 국내 시장 규모: [2025년 예상 규모, 2023-2025 CAGR]
      • 글로벌 시장 규모: [2025년 예상 규모, 2023-2025 CAGR]
      • 성장 동력: [2025년 주요 드라이버 3가지]
      
      ### Porter's 5 Forces 분석
      1. **산업 내 경쟁 강도**: [High/Medium/Low]
         - 주요 경쟁사:
         - 경쟁 양상:
      
      2. **신규 진입 위협**: [High/Medium/Low]
         - 진입 장벽:
         - 최근 신규 진입자:
      
      3. **대체재 위협**: [High/Medium/Low]
         - 주요 대체재:
         - 대체 가능성:
      
      4. **구매자 교섭력**: [High/Medium/Low]
         - 주요 고객:
         - 의존도:
      
      5. **공급자 교섭력**: [High/Medium/Low]
         - 주요 공급사:
         - 전환 비용:
      
      ### SWOT 분석
      **Strengths (강점)**
      • S1:
      • S2:
      
      **Weaknesses (약점)**
      • W1:
      • W2:
      
      **Opportunities (기회)**
      • O1:
      • O2:
      
      **Threats (위협)**
      • T1:
      • T2:
      
      ### [핵심 요약 3줄]
      1. 
      2. 
      3. 
      
      2025년 8월 최신 시장 데이터를 반영하여 BCG 매트릭스 관점에서 분석하세요.
    PROMPT

    call_gpt_api(prompt)
  end

  def analyze_financials
    prompt = <<~PROMPT
      기업명: #{@company_name}
      현재 날짜: 2025년 8월
      
      ## 3. 재무 분석
      
      ### 매출·수익성 추이 (최근 3년 + 2025년 상반기)
      | 구분 | 2023 | 2024 | 2025 상반기 | 2025(E) | CAGR |
      |------|------|------|---------|------|
      | 매출액 |  |  |  |  |
      | 영업이익 |  |  |  |  |
      | 순이익 |  |  |  |  |
      | 영업이익률 |  |  |  |  |
      
      ### 수익 구조 분석
      • 사업부문별 매출 비중:
        - 부문 1: XX%
        - 부문 2: XX%
      • 지역별 매출 비중:
        - 국내: XX%
        - 해외: XX%
      
      ### 주요 재무 지표
      • ROE (자기자본수익률):
      • ROA (총자산수익률):
      • 부채비율:
      • 유동비율:
      • PER (주가수익비율):
      • PBR (주가순자산비율):
      
      ### 현금흐름 분석
      • 영업활동 현금흐름:
      • 투자활동 현금흐름:
      • 재무활동 현금흐름:
      • Free Cash Flow:
      
      ### 벤치마크 비교
      • vs 업계 평균:
      • vs 주요 경쟁사:
      
      ### [핵심 요약 3줄]
      1. 
      2. 
      3. 
      
      2025년 8월 기준 최신 재무 데이터를 반영하여 Goldman Sachs 스타일의 재무 분석을 제공하세요.
    PROMPT

    call_gpt_api(prompt)
  end

  def analyze_strategy
    prompt = <<~PROMPT
      기업명: #{@company_name}
      현재 날짜: 2025년 8월
      
      ## 4. 경영 전략 분석 (2025년 현재)
      
      ### 최근 전략적 이니셔티브 (2025년)
      1. **디지털 전환 (DX)**
         • 2025년 투자 규모:
         • 주요 프로젝트: [2025년 진행 중인 프로젝트]
         • 진행 상황: [2025년 8월 현재]
      
      2. **ESG 경영**
         • E (환경): 
         • S (사회):
         • G (지배구조):
         • ESG 등급:
      
      3. **글로벌 확장**
         • 타겟 시장:
         • 진출 전략:
         • 현지화 전략:
      
      ### M&A 및 투자 활동 (2024-2025년)
      • 최근 M&A: [2024-2025년 거래]
        - 인수 기업:
        - 금액:
        - 시너지:
      • R&D 투자 (2025년):
        - 매출 대비 R&D 비율:
        - 핵심 연구 분야:
      • 설비 투자 (2025년):
        - 투자 규모:
        - 투자 목적:
      
      ### 혁신 역량
      • 특허 보유:
      • 신제품 출시:
      • 파트너십:
      
      ### 조직 문화 및 인재 전략
      • 핵심 가치:
      • 인재 확보 전략:
      • 조직 문화 특징:
      
      ### [핵심 요약 3줄]
      1. 
      2. 
      3. 
      
      2025년 8월 기준 최신 전략과 동향을 반영하여 Bain & Company 스타일의 전략 분석을 제공하세요.
    PROMPT

    call_gpt_api(prompt)
  end

  def analyze_risks
    prompt = <<~PROMPT
      기업명: #{@company_name}
      
      ## 5. 리스크 요인 분석
      
      ### 시장 리스크
      • **경기 민감도**: [High/Medium/Low]
        - 영향 요인:
        - 대응 방안:
      • **경쟁 심화**:
        - 주요 위협:
        - 방어 전략:
      
      ### 운영 리스크
      • **공급망 리스크**:
        - 취약점:
        - 리스크 완화 방안:
      • **기술 변화**:
        - Disruption 가능성:
        - 대응 준비도:
      
      ### 규제 리스크
      • **정책/규제 변화**:
        - 주요 규제:
        - 영향도:
      • **ESG 규제**:
        - 준수 사항:
        - 대응 현황:
      
      ### 재무 리스크
      • **환율 변동**:
        - 노출도:
        - 헤징 전략:
      • **금리 변동**:
        - 영향:
        - 대응:
      
      ### 리스크 매트릭스
      | 리스크 | 발생가능성 | 영향도 | 대응우선순위 |
      |--------|-----------|--------|-------------|
      | 리스크1 | H/M/L | H/M/L | 1-5 |
      | 리스크2 | H/M/L | H/M/L | 1-5 |
      
      ### [핵심 요약 3줄]
      1. 
      2. 
      3. 
      
      리스크를 정량화하여 분석하세요.
    PROMPT

    call_gpt_api(prompt)
  end

  def generate_outlook
    prompt = <<~PROMPT
      기업명: #{@company_name}
      현재 날짜: 2025년 8월
      
      ## 6. 향후 전망
      
      ### 단기 전망 (2025년 하반기 - 2026년 상반기)
      **Base Case 시나리오 (확률 60%)**
      • 매출 성장률: +X%
      • 영업이익률: X%
      • 주요 가정:
      • 핵심 모니터링 지표:
      
      **Bull Case 시나리오 (확률 25%)**
      • 매출 성장률: +X%
      • 상승 요인:
      
      **Bear Case 시나리오 (확률 15%)**
      • 매출 성장률: +X%
      • 하락 요인:
      
      ### 중기 전망 (2026-2028년)
      **성장 동력**
      1. 동력 1:
      2. 동력 2:
      3. 동력 3:
      
      **목표 달성 가능성**
      • 경영진 가이던스:
      • 달성 가능성: [High/Medium/Low]
      • 핵심 변수:
      
      ### 장기 전망 (2028-2030년)
      **메가트렌드 영향**
      • AI/디지털화:
      • ESG/지속가능성:
      • 인구구조 변화:
      
      **전략적 포지셔닝**
      • 목표 시장 지위:
      • 필요 역량:
      • 투자 우선순위:
      
      ### [핵심 요약 3줄]
      1. 
      2. 
      3. 
      
      2025년 8월 현재 상황을 기준으로 시나리오 플래닝 기법을 활용하세요.
    PROMPT

    call_gpt_api(prompt)
  end

  def generate_insights
    prompt = <<~PROMPT
      기업명: #{@company_name}
      
      ## 7. 핵심 인사이트 및 시사점
      
      ### 💼 투자자 관점
      **투자 매력도**: ⭐⭐⭐⭐☆ (4/5)
      
      **Buy 포인트**
      1. 
      2. 
      3. 
      
      **주의 사항**
      1. 
      2. 
      
      **적정 주가 레인지**: 
      • DCF 기준:
      • PER 기준:
      • 목표 주가:
      
      ### 🎯 구직자 관점
      **기업 매력도**: ⭐⭐⭐⭐☆ (4/5)
      
      **입사 추천 이유**
      1. 성장성:
      2. 안정성:
      3. 기업문화:
      
      **고려 사항**
      1. 
      2. 
      
      **유망 직무**
      • 직무 1: [이유]
      • 직무 2: [이유]
      
      ### 🤝 파트너사 관점
      **협업 매력도**: ⭐⭐⭐⭐☆ (4/5)
      
      **협업 기회**
      1. 
      2. 
      
      **시너지 영역**
      1. 
      2. 
      
      ### 📊 종합 평가
      | 항목 | 점수 | 업계 평균 대비 |
      |------|------|--------------|
      | 성장성 | A/B/C/D | +/- |
      | 수익성 | A/B/C/D | +/- |
      | 안정성 | A/B/C/D | +/- |
      | 혁신성 | A/B/C/D | +/- |
      | ESG | A/B/C/D | +/- |
      
      ### 💡 One-line Summary
      > "#{@company_name}는 [핵심 특징]을 보유한 [업계 포지션] 기업으로, [향후 전망]이 예상됨"
      
      맥킨지의 So-What 원칙을 적용하여 작성하세요.
    PROMPT

    call_gpt_api(prompt)
  end

  def call_gpt_api(prompt, max_tokens: 2000)
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
      model: ENV['OPENAI_MODEL'] || 'gpt-4o-mini',
      messages: [
        { 
          role: 'system', 
          content: '당신은 맥킨지, BCG, Bain 출신의 시니어 컨설턴트입니다. 현재 날짜는 2025년 8월입니다. 2025년 최신 정보를 기반으로 전문적이고 데이터 기반의 분석을 제공하며, 통찰력 있는 인사이트를 도출합니다. 한국 기업과 글로벌 기업 모두에 대한 깊은 이해를 가지고 있으며, 2025년 현재 시장 상황과 트렌드를 정확히 파악하고 있습니다.' 
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.3,
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