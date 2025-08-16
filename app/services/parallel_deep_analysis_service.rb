class ParallelDeepAnalysisService
  def initialize(job_analysis, user_profile)
    @job_analysis = job_analysis
    @user_profile = user_profile
    @parallel_service = ParallelOpenaiService.new(model: ENV['ONTOLOGY_MODEL'] || 'gpt-5')
  end
  
  def perform_analysis
    Rails.logger.info "=== 병렬 심층 분석 시작 ==="
    start_time = Time.now
    
    # 모든 분석 프롬프트 준비
    prompts = prepare_all_prompts
    
    # 병렬로 모든 분석 실행
    results = @parallel_service.parallel_calls(
      prompts.values,
      system_prompt: '당신은 채용 전문가이자 인재 매칭 전문가입니다.',
      temperature: 0.3,
      max_tokens: 3000
    )
    
    # 결과 매핑
    analysis_results = {}
    prompts.keys.each_with_index do |key, index|
      if results[index][:success]
        analysis_results[key] = parse_json_response(results[index][:content])
      else
        analysis_results[key] = { error: results[index][:error] }
      end
    end
    
    Rails.logger.info "병렬 분석 완료: #{(Time.now - start_time).round(1)}초"
    
    # 종합 분석
    final_analysis = synthesize_results(analysis_results)
    
    # 결과 저장
    save_analysis_results(final_analysis)
    
    final_analysis
  end
  
  private
  
  def prepare_all_prompts
    {
      skill_analysis: build_skill_analysis_prompt,
      experience_matching: build_experience_matching_prompt,
      cultural_fit: build_cultural_fit_prompt,
      growth_potential: build_growth_potential_prompt,
      competitive_analysis: build_competitive_analysis_prompt,
      risk_assessment: build_risk_assessment_prompt,
      compensation_analysis: build_compensation_analysis_prompt,
      team_dynamics: build_team_dynamics_prompt,
      innovation_potential: build_innovation_potential_prompt,
      leadership_assessment: build_leadership_assessment_prompt
    }
  end
  
  def build_skill_analysis_prompt
    <<~PROMPT
      직무 요구사항과 지원자 역량을 분석하세요:
      
      직무: #{@job_analysis.position}
      요구 기술: #{@job_analysis.required_skills}
      
      지원자 기술: #{@user_profile.technical_skills}
      경력: #{@user_profile.career_history}
      
      다음을 JSON으로 분석하세요:
      1. 완벽 매칭 스킬 (exact_matches)
      2. 부분 매칭 스킬 (partial_matches)
      3. 부족한 스킬 (missing_skills)
      4. 추가 보유 스킬 (additional_skills)
      5. 전체 매칭률 (match_percentage)
      6. 즉시 기여 가능 영역 (immediate_contributions)
      7. 학습 필요 영역 (learning_required)
    PROMPT
  end
  
  def build_experience_matching_prompt
    <<~PROMPT
      지원자의 경험과 직무 요구사항을 매칭 분석하세요:
      
      회사: #{@job_analysis.company_name}
      직무 설명: #{@job_analysis.analysis_result}
      
      지원자 경력: #{@user_profile.career_history}
      프로젝트: #{@user_profile.projects}
      
      JSON으로 분석:
      1. 직접 관련 경험 (direct_experience)
      2. 전이 가능 경험 (transferable_experience)
      3. 리더십 경험 (leadership_experience)
      4. 문제해결 사례 (problem_solving_cases)
      5. 성과 지표 (performance_metrics)
      6. 산업 이해도 (industry_understanding)
    PROMPT
  end
  
  def build_cultural_fit_prompt
    <<~PROMPT
      기업 문화와 지원자 적합도를 분석하세요:
      
      기업 가치: #{@job_analysis.company_values}
      기업 문화: #{extract_company_culture}
      
      지원자 소개: #{@user_profile.introduction}
      지원자 가치관: #{extract_personal_values}
      
      JSON으로 분석:
      1. 가치관 일치도 (value_alignment)
      2. 업무 스타일 적합도 (work_style_fit)
      3. 팀워크 성향 (teamwork_tendency)
      4. 적응력 평가 (adaptability_score)
      5. 장기 근속 가능성 (retention_probability)
    PROMPT
  end
  
  def build_growth_potential_prompt
    <<~PROMPT
      지원자의 성장 잠재력을 평가하세요:
      
      현재 수준: #{current_level_assessment}
      목표 직무: #{@job_analysis.position}
      
      학습 이력: #{learning_history}
      도전 경험: #{challenge_experiences}
      
      JSON으로 평가:
      1. 학습 속도 (learning_velocity)
      2. 도전 정신 (challenge_mindset)
      3. 혁신 역량 (innovation_capability)
      4. 리더십 잠재력 (leadership_potential)
      5. 3년 후 예상 성장 (three_year_projection)
    PROMPT
  end
  
  def build_competitive_analysis_prompt
    <<~PROMPT
      다른 지원자 대비 경쟁력을 분석하세요:
      
      직무: #{@job_analysis.position}
      일반적 지원자 수준: #{estimate_average_candidate}
      
      이 지원자 강점: #{@user_profile.achievements}
      독특한 경험: #{unique_experiences}
      
      JSON으로 분석:
      1. 차별화 포인트 (differentiation_points)
      2. 경쟁 우위 요소 (competitive_advantages)
      3. 약점 보완 전략 (weakness_mitigation)
      4. 예상 순위 (estimated_ranking)
      5. 추천 강도 (recommendation_strength)
    PROMPT
  end
  
  def build_risk_assessment_prompt
    <<~PROMPT
      채용 리스크를 평가하세요:
      
      직무 중요도: #{job_criticality}
      요구 경험: #{@job_analysis.required_skills}
      
      지원자 갭: #{identify_gaps}
      
      JSON으로 평가:
      1. 역량 리스크 (capability_risk)
      2. 적응 리스크 (adaptation_risk)
      3. 이직 리스크 (turnover_risk)
      4. 팀 융합 리스크 (team_integration_risk)
      5. 리스크 완화 방안 (mitigation_strategies)
    PROMPT
  end
  
  def synthesize_results(analysis_results)
    {
      timestamp: Time.current,
      job_analysis_id: @job_analysis.id,
      user_profile_id: @user_profile.id,
      
      # 개별 분석 결과
      skill_match: analysis_results[:skill_analysis],
      experience_match: analysis_results[:experience_matching],
      cultural_fit: analysis_results[:cultural_fit],
      growth_potential: analysis_results[:growth_potential],
      competitive_position: analysis_results[:competitive_analysis],
      risk_assessment: analysis_results[:risk_assessment],
      
      # 종합 점수
      overall_score: calculate_overall_score(analysis_results),
      
      # 핵심 인사이트
      key_insights: extract_key_insights(analysis_results),
      
      # 추천사항
      recommendations: generate_recommendations(analysis_results),
      
      # 액션 아이템
      action_items: generate_action_items(analysis_results)
    }
  end
  
  def calculate_overall_score(results)
    weights = {
      skill_analysis: 0.25,
      experience_matching: 0.20,
      cultural_fit: 0.15,
      growth_potential: 0.15,
      competitive_analysis: 0.15,
      risk_assessment: 0.10
    }
    
    total_score = 0
    weights.each do |key, weight|
      if results[key] && results[key][:match_percentage]
        total_score += results[key][:match_percentage].to_f * weight
      end
    end
    
    total_score.round(1)
  end
  
  def parse_json_response(content)
    JSON.parse(content, symbolize_names: true)
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parsing error: #{e.message}"
    { error: "Failed to parse response", raw: content }
  end
  
  def save_analysis_results(analysis)
    # OntologyAnalysis 테이블에 저장
    OntologyAnalysis.create!(
      job_analysis_id: @job_analysis.id,
      user_profile_id: @user_profile.id,
      analysis_status: 'completed',
      match_score: analysis[:overall_score],
      matching_result: analysis,
      analyzed_at: Time.current
    )
  end
  
  # Helper methods
  def extract_company_culture
    # 기업 문화 추출 로직
    @job_analysis.company_values || "혁신, 협업, 성장"
  end
  
  def extract_personal_values
    # 개인 가치관 추출
    @user_profile.introduction || ""
  end
  
  def current_level_assessment
    # 현재 수준 평가
    years = extract_years_of_experience
    "경력 #{years}년"
  end
  
  def extract_years_of_experience
    # 경력 연수 계산
    return 0 unless @user_profile.career_history
    
    careers = JSON.parse(@user_profile.career_history.to_json)
    # 경력 계산 로직
    3 # 예시
  rescue
    0
  end
  
  def learning_history
    @user_profile.education || ""
  end
  
  def challenge_experiences
    @user_profile.achievements || ""
  end
  
  def estimate_average_candidate
    "#{@job_analysis.position} 일반 지원자 수준"
  end
  
  def unique_experiences
    @user_profile.projects || ""
  end
  
  def job_criticality
    "높음" # 실제로는 분석 필요
  end
  
  def identify_gaps
    # 갭 분석 로직
    "일부 기술 스택 경험 부족"
  end
  
  def extract_key_insights(results)
    insights = []
    
    # 각 분석에서 핵심 인사이트 추출
    results.each do |key, value|
      next if value[:error]
      
      case key
      when :skill_analysis
        if value[:match_percentage] && value[:match_percentage] > 80
          insights << "높은 기술 적합도 (#{value[:match_percentage]}%)"
        end
      when :cultural_fit
        if value[:value_alignment] && value[:value_alignment] > 75
          insights << "우수한 문화 적합성"
        end
      when :growth_potential
        if value[:learning_velocity] == "fast"
          insights << "빠른 학습 능력 보유"
        end
      end
    end
    
    insights
  end
  
  def generate_recommendations(results)
    recommendations = []
    
    # 기술 갭이 있으면 학습 추천
    if results[:skill_analysis] && results[:skill_analysis][:missing_skills]
      recommendations << {
        type: "skill_development",
        priority: "high",
        action: "부족한 기술 학습 필요: #{results[:skill_analysis][:missing_skills].join(', ')}"
      }
    end
    
    # 문화 적합도가 높으면 강조
    if results[:cultural_fit] && results[:cultural_fit][:value_alignment] > 80
      recommendations << {
        type: "interview_strategy",
        priority: "medium",
        action: "면접에서 기업 가치관과의 일치점 강조"
      }
    end
    
    recommendations
  end
  
  def generate_action_items(results)
    [
      "자기소개서에 핵심 강점 부각",
      "포트폴리오 업데이트",
      "면접 준비 집중 영역 설정"
    ]
  end
end