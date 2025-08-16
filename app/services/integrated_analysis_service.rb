class IntegratedAnalysisService
  def initialize(user_profile, job_posting, company_name)
    @user_profile = user_profile
    @job_posting = job_posting
    @company_name = company_name
    @parallel_service = ParallelOpenaiService.new
  end
  
  def perform_complete_analysis
    Rails.logger.info "=== 통합 분석 시작 (맥락 + 온톨로지) ==="
    
    # 병렬로 두 분석 동시 실행
    futures = []
    
    # 맥락 기반 분석
    futures << Concurrent::Future.execute do
      perform_contextual_analysis
    end
    
    # 온톨로지 분석
    futures << Concurrent::Future.execute do
      perform_ontology_analysis
    end
    
    context_result = futures[0].value(30)
    ontology_result = futures[1].value(30)
    
    # 통합 인사이트 생성
    integrated_insights = synthesize_insights(context_result, ontology_result)
    
    # 전략적 자소서 생성
    strategic_cover_letter = generate_strategic_cover_letter(integrated_insights)
    
    {
      contextual_analysis: context_result,
      ontology_analysis: ontology_result,
      integrated_insights: integrated_insights,
      cover_letter: strategic_cover_letter,
      visualization: generate_visualization_data(integrated_insights)
    }
  end
  
  private
  
  def perform_contextual_analysis
    {
      # 기업 현재 상황
      company_context: {
        recent_news: analyze_recent_news,
        urgent_needs: identify_urgent_needs,
        industry_trends: analyze_industry_trends,
        competitor_moves: track_competitor_moves,
        hiring_urgency: calculate_urgency_score
      },
      
      # 시의성 매칭
      timing_match: {
        why_now: generate_why_now_narrative,
        perfect_timing_score: calculate_timing_score,
        opportunity_window: identify_opportunity_window
      },
      
      # 숨은 강점 발견
      hidden_strengths: {
        implicit_skills: discover_implicit_skills,
        unique_combinations: find_unique_combinations,
        transferable_value: identify_transferable_value
      }
    }
  end
  
  def perform_ontology_analysis
    {
      # 역량 매칭
      skill_matching: {
        technical_skills: match_technical_skills,
        soft_skills: match_soft_skills,
        experience_mapping: map_experiences,
        achievement_relevance: analyze_achievements
      },
      
      # 정량적 평가
      quantitative_scores: {
        overall_match: calculate_overall_match,
        skill_coverage: calculate_skill_coverage,
        experience_depth: measure_experience_depth,
        growth_potential: assess_growth_potential
      },
      
      # 갭 분석
      gap_analysis: {
        missing_skills: identify_missing_skills,
        improvement_areas: suggest_improvements,
        learning_roadmap: create_learning_plan
      }
    }
  end
  
  def synthesize_insights(context, ontology)
    {
      # 핵심 메시지
      core_message: generate_core_message(context, ontology),
      
      # 차별화 전략
      differentiation_strategy: {
        timing_advantage: context[:timing_match][:why_now],
        capability_proof: ontology[:quantitative_scores][:overall_match],
        unique_value: combine_unique_values(context, ontology)
      },
      
      # 리스크 완화
      risk_mitigation: {
        skill_gaps: ontology[:gap_analysis][:missing_skills],
        mitigation_plan: generate_mitigation_strategy(context, ontology)
      },
      
      # 액션 플랜
      action_plan: {
        immediate_value: define_immediate_contributions(context),
        short_term_goals: set_3_month_objectives(ontology),
        long_term_vision: create_1_year_roadmap(context, ontology)
      }
    }
  end
  
  def generate_strategic_cover_letter(insights)
    prompt = build_integrated_prompt(insights)
    
    response = @parallel_service.call_api(
      prompt,
      system_prompt: '당신은 맥락과 역량을 완벽하게 결합하는 전략적 자소서 전문가입니다.',
      temperature: 0.8,
      max_tokens: 3000
    )
    
    if response[:success]
      polish_cover_letter(response[:content], insights)
    else
      generate_fallback_cover_letter(insights)
    end
  end
  
  def build_integrated_prompt(insights)
    <<~PROMPT
      다음 통합 분석을 바탕으로 전략적 자소서를 작성하세요:
      
      [맥락 기반 인사이트]
      - 기업 긴급 니즈: #{insights[:differentiation_strategy][:timing_advantage]}
      - 완벽한 타이밍 이유: #{insights[:core_message]}
      
      [온톨로지 기반 역량]
      - 정량적 매칭도: #{insights[:differentiation_strategy][:capability_proof]}%
      - 핵심 역량 증명: #{format_skills_proof(insights)}
      
      [통합 전략]
      - 차별화 포인트: #{insights[:differentiation_strategy][:unique_value]}
      - 즉시 기여 가능 영역: #{insights[:action_plan][:immediate_value]}
      
      작성 지침:
      1. 도입부: 시의성 강조 (왜 지금인가)
      2. 본문1: 정량적 역량 매칭 증명
      3. 본문2: 기업 맥락과 개인 경험 연결
      4. 본문3: 구체적 기여 계획
      5. 맺음: 장기 비전과 성장 의지
      
      1000자 내외로 작성하되, 맥락과 역량이 자연스럽게 융합되도록 하세요.
    PROMPT
  end
  
  def generate_visualization_data(insights)
    {
      # 레이더 차트 데이터
      radar_chart: {
        categories: ['기술 매칭', '경험 깊이', '시의성', '성장 잠재력', '문화 적합도'],
        scores: extract_radar_scores(insights)
      },
      
      # 매칭 매트릭스
      matching_matrix: {
        urgent_needs: extract_urgent_needs_matrix(insights),
        capability_coverage: extract_capability_matrix(insights)
      },
      
      # 타임라인
      contribution_timeline: {
        immediate: insights[:action_plan][:immediate_value],
        short_term: insights[:action_plan][:short_term_goals],
        long_term: insights[:action_plan][:long_term_vision]
      }
    }
  end
  
  # 헬퍼 메서드들
  def analyze_recent_news
    # CompanyNewsCrawlerService 활용
    company = Company.find_or_create_by(name: @company_name)
    crawler = CompanyNewsCrawlerService.new(company)
    news = crawler.crawl_all_sources
    
    # AI로 맥락 분석
    analyze_news_context(news)
  end
  
  def match_technical_skills
    return {} unless @user_profile && @job_posting
    
    user_skills = extract_user_skills(@user_profile)
    job_requirements = extract_job_requirements(@job_posting)
    
    # 온톨로지 매칭 로직
    calculate_skill_similarity(user_skills, job_requirements)
  end
  
  def generate_core_message(context, ontology)
    timing_score = context[:timing_match][:perfect_timing_score]
    match_score = ontology[:quantitative_scores][:overall_match]
    
    if timing_score > 90 && match_score > 85
      "완벽한 시점에 최적의 역량을 갖춘 인재"
    elsif timing_score > 90
      "지금 가장 필요한 시점의 준비된 인재"
    elsif match_score > 85
      "검증된 역량으로 즉시 기여 가능한 인재"
    else
      "열정과 잠재력으로 함께 성장할 인재"
    end
  end
  
  def combine_unique_values(context, ontology)
    # 맥락적 차별화 + 역량적 차별화 결합
    contextual_uniqueness = context[:hidden_strengths][:unique_combinations]
    capability_uniqueness = ontology[:skill_matching][:technical_skills]
    
    {
      combined_value: merge_unique_points(contextual_uniqueness, capability_uniqueness),
      synergy_effect: calculate_synergy(contextual_uniqueness, capability_uniqueness)
    }
  end
  
  def calculate_urgency_score
    factors = {
      reposting_frequency: check_reposting_frequency,
      competitor_hiring: analyze_competitor_hiring,
      project_timeline: extract_project_urgency,
      market_pressure: assess_market_pressure
    }
    
    factors.values.sum / factors.size * 100
  end
  
  def extract_radar_scores(insights)
    [
      insights[:differentiation_strategy][:capability_proof] || 0,
      calculate_experience_score(insights),
      insights[:core_message].include?('완벽한 시점') ? 95 : 70,
      calculate_growth_score(insights),
      calculate_culture_fit(insights)
    ]
  end
end