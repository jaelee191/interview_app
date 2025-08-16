class HiddenStrengthDiscoveryService
  def initialize(user_profile)
    @profile = user_profile
  end

  def discover_hidden_strengths
    {
      # 1. 경험에서 도출되는 암묵적 역량
      implicit_competencies: extract_implicit_competencies,
      
      # 2. 패턴 분석을 통한 강점
      behavioral_patterns: analyze_behavioral_patterns,
      
      # 3. 전이 가능한 역량
      transferable_skills: identify_transferable_skills,
      
      # 4. 독특한 조합 강점
      unique_combinations: find_unique_skill_combinations,
      
      # 5. 성장 잠재력 지표
      growth_indicators: measure_growth_potential
    }
  end

  private

  def extract_implicit_competencies
    competencies = []
    
    # 프로젝트 경험에서 도출
    if @profile.projects.present?
      projects = parse_projects(@profile.projects)
      projects.each do |project|
        # 명시되지 않은 역량 추론
        competencies += infer_from_project(project)
      end
    end
    
    # 경력에서 도출
    if @profile.career_history.present?
      careers = parse_careers(@profile.career_history)
      careers.each do |career|
        competencies += infer_from_career(career)
      end
    end
    
    deduplicate_and_score(competencies)
  end

  def infer_from_project(project)
    implicit_skills = []
    
    # 예: "3개월 단독 개발" → 자기관리, 독립성, 책임감
    if project[:description].match?(/단독|혼자|개인/)
      implicit_skills << { skill: "자기주도성", evidence: project[:description], confidence: 0.9 }
      implicit_skills << { skill: "책임감", evidence: project[:description], confidence: 0.85 }
    end
    
    # 예: "팀원 5명과 협업" → 협업, 의사소통
    if project[:description].match?(/팀|협업|함께/)
      team_size = extract_team_size(project[:description])
      if team_size && team_size > 3
        implicit_skills << { skill: "대규모 팀 협업", evidence: project[:description], confidence: 0.8 }
      end
    end
    
    # 예: "기한 내 완료" → 시간관리, 실행력
    if project[:description].match?(/기한|데드라인|일정/)
      implicit_skills << { skill: "시간관리", evidence: project[:description], confidence: 0.75 }
    end
    
    # 예: "20% 성능 개선" → 문제해결, 최적화
    if project[:description].match?(/개선|최적화|효율/)
      percentage = extract_improvement_percentage(project[:description])
      if percentage && percentage > 10
        implicit_skills << { skill: "성과창출력", evidence: project[:description], confidence: 0.9 }
      end
    end
    
    implicit_skills
  end

  def analyze_behavioral_patterns
    patterns = {}
    
    # 도전적 과제 선호도
    patterns[:challenge_seeker] = calculate_challenge_preference
    
    # 학습 속도
    patterns[:fast_learner] = calculate_learning_velocity
    
    # 리더십 성향
    patterns[:leadership_tendency] = detect_leadership_patterns
    
    # 혁신 성향
    patterns[:innovation_mindset] = measure_innovation_tendency
    
    patterns
  end

  def identify_transferable_skills
    transferable = []
    
    # 산업 불문 핵심 역량
    core_skills = extract_core_skills
    
    # 다른 도메인에 적용 가능한 역량
    core_skills.each do |skill|
      applications = find_cross_domain_applications(skill)
      if applications.any?
        transferable << {
          skill: skill,
          applications: applications,
          versatility_score: calculate_versatility(skill)
        }
      end
    end
    
    transferable.sort_by { |t| -t[:versatility_score] }
  end

  def find_unique_skill_combinations
    skills = all_identified_skills
    combinations = []
    
    # 2-3개 스킬의 독특한 조합 찾기
    skills.combination(2).each do |combo|
      rarity = calculate_combination_rarity(combo)
      if rarity > 0.7  # 희귀한 조합
        combinations << {
          skills: combo,
          rarity: rarity,
          synergy: calculate_synergy(combo),
          market_value: estimate_market_value(combo)
        }
      end
    end
    
    combinations.sort_by { |c| -c[:market_value] }.first(5)
  end

  def measure_growth_potential
    {
      learning_curve: analyze_skill_acquisition_rate,
      adaptability: measure_career_adaptability,
      complexity_handling: assess_problem_complexity_growth,
      leadership_progression: track_responsibility_growth,
      domain_expansion: count_domain_transitions
    }
  end

  def calculate_challenge_preference
    challenging_keywords = ["도전", "새로운", "처음", "혁신", "개척"]
    
    challenge_count = 0
    total_experiences = 0
    
    [@profile.projects, @profile.career_history].each do |data|
      next unless data.present?
      
      text = data.to_s.downcase
      challenging_keywords.each do |keyword|
        challenge_count += text.scan(keyword).count
      end
      total_experiences += 1
    end
    
    return 0 if total_experiences == 0
    (challenge_count.to_f / total_experiences).round(2)
  end
end