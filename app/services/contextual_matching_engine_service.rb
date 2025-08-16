class ContextualMatchingEngineService
  def initialize(company_context, hidden_strengths, job_requirements)
    @company_context = company_context
    @hidden_strengths = hidden_strengths
    @job_requirements = job_requirements
  end

  def generate_contextual_insights
    {
      # 1. 핵심 연결점 발견
      key_connections: find_key_connections,
      
      # 2. 타이밍 기반 매칭
      timing_relevance: analyze_timing_match,
      
      # 3. 문제-해결 매칭
      problem_solution_fit: match_problems_to_solutions,
      
      # 4. 스토리텔링 포인트
      narrative_points: generate_narrative_points,
      
      # 5. 차별화 전략
      differentiation_strategy: create_differentiation_strategy
    }
  end

  private

  def find_key_connections
    connections = []
    
    # 기업 이슈와 지원자 강점의 교집합 찾기
    @company_context[:business_issues].each do |issue_type, issue_data|
      next unless issue_data[:score] > 0.5
      
      relevant_strengths = find_relevant_strengths_for_issue(issue_type)
      
      if relevant_strengths.any?
        connections << {
          company_need: issue_type,
          urgency: issue_data[:score],
          candidate_strength: relevant_strengths,
          connection_strength: calculate_connection_strength(issue_type, relevant_strengths),
          narrative: generate_connection_narrative(issue_type, relevant_strengths)
        }
      end
    end
    
    connections.sort_by { |c| -c[:connection_strength] }
  end

  def find_relevant_strengths_for_issue(issue_type)
    relevant = []
    
    case issue_type
    when :expansion
      # 확장 이슈 → 실행력, 적응력, 성과창출 강점 매칭
      relevant += @hidden_strengths[:implicit_competencies].select do |comp|
        ["실행력", "적응력", "성과창출력", "시장개척"].any? { |k| comp[:skill].include?(k) }
      end
      
    when :transformation
      # 전환 이슈 → 혁신, 학습력, 변화관리 강점 매칭
      relevant += @hidden_strengths[:behavioral_patterns].select do |pattern, score|
        [:innovation_mindset, :fast_learner].include?(pattern) && score > 0.6
      end.map { |p, s| { skill: p.to_s, confidence: s } }
      
    when :crisis_response
      # 위기 대응 → 문제해결, 회복탄력성, 효율화 강점 매칭
      relevant += @hidden_strengths[:implicit_competencies].select do |comp|
        ["문제해결", "위기관리", "효율", "최적화"].any? { |k| comp[:skill].include?(k) }
      end
      
    when :talent_war
      # 인재 경쟁 → 팀빌딩, 문화적합성, 충성도 강점 매칭
      relevant += @hidden_strengths[:unique_combinations].select do |combo|
        combo[:skills].any? { |s| s.match?(/협업|팀|문화|소통/) }
      end.map { |c| { skill: c[:skills].join("+"), confidence: c[:synergy] } }
    end
    
    relevant
  end

  def analyze_timing_match
    timing_factors = {
      urgency_alignment: calculate_urgency_alignment,
      market_timing: assess_market_timing_fit,
      career_timing: evaluate_career_stage_fit,
      skill_readiness: measure_immediate_readiness
    }
    
    {
      overall_score: timing_factors.values.sum / timing_factors.size,
      factors: timing_factors,
      recommendation: generate_timing_recommendation(timing_factors)
    }
  end

  def match_problems_to_solutions
    problem_solution_pairs = []
    
    # 기업의 문제점 추출
    company_problems = extract_company_problems
    
    company_problems.each do |problem|
      # 지원자의 관련 해결 경험 찾기
      solutions = find_candidate_solutions(problem)
      
      if solutions.any?
        problem_solution_pairs << {
          problem: problem[:description],
          problem_severity: problem[:severity],
          candidate_solutions: solutions,
          fit_score: calculate_solution_fit(problem, solutions),
          proof_points: extract_proof_points(solutions)
        }
      end
    end
    
    problem_solution_pairs.sort_by { |ps| -ps[:fit_score] }
  end

  def generate_narrative_points
    narratives = []
    
    # 1. "왜 지금 내가 필요한가" 스토리
    narratives << {
      theme: "timing_why_me",
      headline: generate_timing_headline,
      supporting_points: [
        timing_match_point,
        urgency_response_point,
        readiness_point
      ]
    }
    
    # 2. "내가 해결할 수 있는 것" 스토리
    narratives << {
      theme: "problem_solver",
      headline: generate_problem_solver_headline,
      supporting_points: problem_solution_examples
    }
    
    # 3. "숨은 가치" 스토리
    narratives << {
      theme: "hidden_value",
      headline: generate_hidden_value_headline,
      supporting_points: unique_value_propositions
    }
    
    narratives
  end

  def create_differentiation_strategy
    {
      unique_angle: find_unique_positioning,
      competitors_blindspot: identify_competitor_blindspots,
      unexpected_strengths: highlight_unexpected_fits,
      future_value: project_future_contributions,
      cultural_amplifiers: identify_cultural_multipliers
    }
  end

  def generate_connection_narrative(issue_type, strengths)
    issue_description = describe_issue(issue_type)
    strength_description = strengths.map { |s| s[:skill] }.join(", ")
    
    templates = [
      "귀사가 #{issue_description} 시점에, 제 #{strength_description} 역량이 즉시 기여할 수 있습니다.",
      "#{issue_description}라는 도전과제를 #{strength_description} 경험으로 함께 해결하고 싶습니다.",
      "제가 보유한 #{strength_description} 역량은 귀사의 #{issue_description} 국면에 최적화되어 있습니다."
    ]
    
    templates.sample
  end

  def describe_issue(issue_type)
    descriptions = {
      expansion: "새로운 시장으로 확장하는",
      transformation: "디지털 전환을 추진하는",
      crisis_response: "시장 변화에 대응하는",
      talent_war: "핵심 인재를 확보하려는"
    }
    descriptions[issue_type] || "성장하는"
  end

  def calculate_connection_strength(issue_type, strengths)
    # 이슈 긴급도 * 강점 확신도 * 매칭 정확도
    issue_urgency = @company_context[:business_issues][issue_type][:score]
    strength_confidence = strengths.map { |s| s[:confidence] || 0.5 }.max
    matching_accuracy = estimate_matching_accuracy(issue_type, strengths)
    
    (issue_urgency * strength_confidence * matching_accuracy).round(2)
  end
end