class IntelligentCoverLetterGeneratorService
  def initialize(user_profile, job_posting_url_or_data, company_name)
    @user_profile = user_profile
    @job_posting = job_posting_url_or_data
    @company_name = company_name
    @parallel_service = ParallelOpenaiService.new(model: ENV["OPENAI_MODEL"] || "gpt-4.1")
  end

  def generate
    Rails.logger.info "=== 지능형 자소서 생성 시작 (병렬 처리) ==="

    # 병렬 처리로 1-3단계 동시 실행
    start_time = Time.now

    futures = []

    # Step 1: 기업 맥락 분석 (비동기)
    Rails.logger.info "1. 기업 현재 이슈 분석 중..."
    futures << Concurrent::Future.execute do
      analyze_company_context
    end

    # Step 2: 지원자 숨은 강점 발견 (비동기)
    Rails.logger.info "2. 지원자 숨은 강점 발견 중..."
    futures << Concurrent::Future.execute do
      discover_hidden_strengths
    end

    # Step 3: 채용공고 요구사항 분석 (비동기)
    Rails.logger.info "3. 채용공고 분석 중..."
    futures << Concurrent::Future.execute do
      analyze_job_requirements
    end

    # 모든 분석 완료 대기
    company_context = futures[0].value(30)
    hidden_strengths = futures[1].value(30)
    job_requirements = futures[2].value(30)

    Rails.logger.info "병렬 분석 완료: #{(Time.now - start_time).round(1)}초"

    # Step 4: 맥락적 연결
    Rails.logger.info "4. 맥락적 인사이트 생성 중..."
    contextual_insights = generate_contextual_insights(
      company_context,
      hidden_strengths,
      job_requirements
    )

    # Step 5: 자소서 생성
    Rails.logger.info "5. 차별화된 자소서 작성 중..."
    cover_letter = compose_cover_letter(contextual_insights)

    {
      cover_letter: cover_letter,
      insights: contextual_insights,
      metadata: {
        company_context: summarize_context(company_context),
        discovered_strengths: summarize_strengths(hidden_strengths),
        key_connections: contextual_insights[:key_connections].first(3)
      }
    }
  end

  private

  def analyze_company_context
    CompanyContextAnalyzerService.new(@company_name, @job_posting).analyze_current_context
  end

  def discover_hidden_strengths
    # 내장된 숨은 강점 발견 로직
    return {} unless @user_profile

    {
      implicit_competencies: extract_implicit_competencies,
      behavioral_patterns: analyze_behavioral_patterns,
      transferable_skills: identify_transferable_skills,
      unique_combinations: find_unique_skill_combinations
    }
  end

  def analyze_job_requirements
    # 기존 JobPostingAnalyzerService 활용 또는 새로 구현
    {
      required_skills: extract_required_skills,
      responsibilities: extract_responsibilities,
      qualifications: extract_qualifications,
      preferred_traits: extract_preferred_traits
    }
  end

  def generate_contextual_insights(company_context, hidden_strengths, job_requirements)
    # 내장된 맥락적 매칭 로직
    {
      key_connections: find_key_connections(company_context, hidden_strengths),
      timing_relevance: analyze_timing_match(company_context),
      problem_solution_fit: match_problems_to_solutions(company_context, hidden_strengths),
      narrative_points: generate_narrative_points(company_context, hidden_strengths),
      differentiation_strategy: create_differentiation_strategy(hidden_strengths)
    }
  end

  def compose_cover_letter(insights)
    sections = []

    # 도입부: 시의적절한 지원 동기
    sections << compose_introduction(insights)

    # 본문1: 기업 이슈에 대한 이해와 해결 능력
    sections << compose_problem_solution_section(insights)

    # 본문2: 숨은 강점과 독특한 가치
    sections << compose_unique_value_section(insights)

    # 본문3: 구체적 기여 방안
    sections << compose_contribution_section(insights)

    # 맺음말: 미래 비전 공유
    sections << compose_conclusion(insights)

    draft = sections.join("\n\n")

    # AI로 최종 다듬기
    polish_with_ai(draft, insights)
  end

  def polish_with_ai(draft, insights)
    return draft unless ENV["OPENAI_API_KEY"].present?

    prompt = <<~PROMPT
      다음은 AI가 생성한 자기소개서 초안입니다.#{' '}
      이를 더 자연스럽고 설득력 있게 다듬어주세요.

      기업: #{@company_name}
      직무: #{@job_posting[:position] if @job_posting.is_a?(Hash)}

      핵심 연결점:
      #{insights[:key_connections].map { |c| "- #{c[:narrative]}" }.join("\n") if insights[:key_connections]}

      초안:
      #{draft}

      다음 사항을 반영해 수정해주세요:
      1. 진정성 있고 개인적인 톤 유지
      2. 구체적인 숫자와 성과 포함
      3. 기업 맥락과 자연스러운 연결
      4. 차별화된 표현 사용
      5. 1000자 내외로 조정

      수정된 자기소개서만 출력해주세요.
    PROMPT

    # 병렬 서비스 사용
    response = @parallel_service.call_api(
      prompt,
      system_prompt: "\uB2F9\uC2E0\uC740 \uCC44\uC6A9 \uC804\uBB38\uAC00\uC774\uC790 \uC790\uAE30\uC18C\uAC1C\uC11C \uC791\uC131 \uC804\uBB38\uAC00\uC785\uB2C8\uB2E4.",
      temperature: 0.8,
      max_tokens: 2000
    )

    if response[:success]
      response[:content]
    else
      Rails.logger.error "Failed to polish cover letter: #{response[:error]}"
      draft
    end
  end

  def call_openai_api(prompt, model: "gpt-4.1")
    require "net/http"
    require "json"

    uri = URI("https://api.openai.com/v1/chat/completions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{ENV['OPENAI_API_KEY']}"
    request["Content-Type"] = "application/json"

    request.body = {
      model: model,
      messages: [
        {
          role: "system",
          content: "\uB2F9\uC2E0\uC740 \uCC44\uC6A9 \uC804\uBB38\uAC00\uC774\uC790 \uC790\uAE30\uC18C\uAC1C\uC11C \uC791\uC131 \uC804\uBB38\uAC00\uC785\uB2C8\uB2E4. \uC9C0\uC6D0\uC790\uC758 \uAC15\uC810\uC744 \uAE30\uC5C5 \uB2C8\uC988\uC640 \uC5F0\uACB0\uD558\uC5EC \uC124\uB4DD\uB825 \uC788\uB294 \uC790\uAE30\uC18C\uAC1C\uC11C\uB97C \uC791\uC131\uD569\uB2C8\uB2E4."
        },
        { role: "user", content: prompt }
      ],
      temperature: 0.8,
      max_tokens: 2000
    }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)

    if result["choices"]
      { success: true, content: result["choices"].first["message"]["content"] }
    else
      { success: false, error: result["error"] }
    end
  rescue => e
    { success: false, error: e.message }
  end

  def compose_introduction(insights)
    timing = insights[:timing_relevance]
    key_connection = insights[:key_connections].first

    intro = []

    # 시의적절한 인사
    if key_connection && key_connection[:urgency] > 0.7
      intro << "#{@company_name}이 #{key_connection[:company_need]}의 중요한 시점을 맞이한 지금, "
      intro << "제 #{key_connection[:candidate_strength].first[:skill]} 역량으로 함께하고자 지원합니다."
    else
      intro << "#{@company_name}의 #{extract_company_vision}에 깊이 공감하며, "
      intro << "제 경험과 역량으로 기여하고자 지원합니다."
    end

    intro.join
  end

  def compose_problem_solution_section(insights)
    problem_solutions = insights[:problem_solution_fit].first(2)

    return "" if problem_solutions.empty?

    section = [ "[기업 과제 해결 역량]" ]

    problem_solutions.each do |ps|
      section << "#{ps[:problem]}라는 과제에 대해, "
      section << "저는 #{ps[:candidate_solutions].first} 경험을 통해 "
      section << "#{ps[:proof_points].first}를 달성한 바 있습니다."
    end

    section.join("\n")
  end

  def compose_unique_value_section(insights)
    differentiation = insights[:differentiation_strategy]
    hidden_strengths = insights[:narrative_points].find { |n| n[:theme] == "hidden_value" }

    section = [ "[차별화된 역량]" ]

    if differentiation[:unique_angle]
      section << differentiation[:unique_angle]
    end

    if hidden_strengths
      section << hidden_strengths[:headline]
      hidden_strengths[:supporting_points].each do |point|
        section << "• #{point}"
      end
    end

    section.join("\n")
  end

  def compose_contribution_section(insights)
    section = [ "[즉시 기여 가능한 영역]" ]

    # 단기 기여
    section << "입사 즉시: #{immediate_contributions(insights).join(', ')}"

    # 중기 기여
    section << "3-6개월 내: #{midterm_contributions(insights).join(', ')}"

    # 장기 비전
    section << "1년 후 목표: #{longterm_vision(insights)}"

    section.join("\n")
  end

  def compose_conclusion(insights)
    future_value = insights[:differentiation_strategy][:future_value]

    conclusion = []
    conclusion << "#{@company_name}과 함께 성장하며"
    conclusion << future_value if future_value
    conclusion << "귀사의 핵심 인재가 되고자 합니다."

    conclusion.join(" ")
  end

  def immediate_contributions(insights)
    insights[:key_connections].map do |conn|
      "#{conn[:candidate_strength].first[:skill]} 활용한 #{simplified_need(conn[:company_need])}"
    end.first(2)
  end

  def simplified_need(need)
    {
      expansion: "시장 확대 지원",
      transformation: "혁신 프로세스 구축",
      crisis_response: "효율화 달성",
      talent_war: "팀 역량 강화"
    }[need] || "성과 창출"
  end

  # 내장된 숨은 강점 발견 메서드들
  def extract_implicit_competencies
    return [] unless @user_profile

    competencies = []

    # 프로젝트에서 역량 추론
    if @user_profile.projects.present?
      projects_text = @user_profile.projects.to_s

      if projects_text.match?(/단독|혼자|개인/)
        competencies << { skill: "자기주도성", confidence: 0.9 }
      end

      if projects_text.match?(/팀|협업|함께/)
        competencies << { skill: "협업능력", confidence: 0.8 }
      end

      if projects_text.match?(/개선|최적화|효율/)
        competencies << { skill: "성과창출력", confidence: 0.9 }
      end
    end

    competencies
  end

  def analyze_behavioral_patterns
    return {} unless @user_profile

    {
      challenge_seeker: calculate_challenge_preference,
      fast_learner: 0.8, # 기본값
      leadership_tendency: 0.7,
      innovation_mindset: 0.6
    }
  end

  def identify_transferable_skills
    return [] unless @user_profile

    core_skills = []

    if @user_profile.career_history.present?
      career_text = @user_profile.career_history.to_s

      core_skills << { skill: "문제해결", versatility_score: 0.9 } if career_text.include?("해결")
      core_skills << { skill: "커뮤니케이션", versatility_score: 0.8 } if career_text.include?("소통")
      core_skills << { skill: "분석력", versatility_score: 0.7 } if career_text.include?("분석")
    end

    core_skills
  end

  def find_unique_skill_combinations
    skills = extract_implicit_competencies
    return [] if skills.size < 2

    combinations = []
    skills.combination(2).each do |combo|
      combinations << {
        skills: combo.map { |s| s[:skill] },
        rarity: 0.8,
        synergy: 0.7,
        market_value: 0.8
      }
    end

    combinations.first(3)
  end

  def calculate_challenge_preference
    return 0.5 unless @user_profile

    challenging_keywords = [ "도전", "새로운", "처음", "혁신", "개척" ]
    challenge_count = 0
    total_text = [ @user_profile.projects, @user_profile.career_history ].compact.join(" ")

    challenging_keywords.each do |keyword|
      challenge_count += total_text.downcase.scan(keyword).count
    end

    [ challenge_count * 0.2, 1.0 ].min
  end

  # 내장된 맥락적 매칭 메서드들
  def find_key_connections(company_context, hidden_strengths)
    connections = []

    if company_context.is_a?(Hash) && company_context[:business_issues]
      company_context[:business_issues].each do |issue_type, issue_data|
        next unless issue_data.is_a?(Hash) && issue_data[:score] && issue_data[:score] > 0.5

        relevant_strengths = hidden_strengths[:implicit_competencies] || []

        if relevant_strengths.any?
          connections << {
            company_need: issue_type,
            urgency: issue_data[:score],
            candidate_strength: relevant_strengths.first(2),
            connection_strength: 0.8,
            narrative: "#{issue_type} 과제 해결에 #{relevant_strengths.first[:skill]} 역량 활용 가능"
          }
        end
      end
    end

    connections.first(3)
  end

  def analyze_timing_match(company_context)
    {
      perfect_timing_score: 85,
      opportunity_window: "현재 최적 시점",
      why_now: "기업의 현재 과제와 지원자 역량이 완벽 매칭"
    }
  end

  def match_problems_to_solutions(company_context, hidden_strengths)
    solutions = []

    # 간단한 문제-해결 매칭
    if hidden_strengths[:implicit_competencies]
      hidden_strengths[:implicit_competencies].each do |competency|
        solutions << {
          problem: "효율성 개선 필요",
          candidate_solutions: [ competency[:skill] ],
          fit_score: competency[:confidence] || 0.8,
          proof_points: [ "관련 프로젝트 경험" ]
        }
      end
    end

    solutions.first(2)
  end

  def generate_narrative_points(company_context, hidden_strengths)
    [
      {
        theme: "timing_why_me",
        headline: "지금이 바로 최적의 시점",
        supporting_points: [ "기업 니즈와 완벽 매칭", "즉시 기여 가능한 역량" ]
      },
      {
        theme: "problem_solver",
        headline: "검증된 문제해결 역량",
        supporting_points: [ "구체적 성과 달성", "다양한 도전 경험" ]
      }
    ]
  end

  def create_differentiation_strategy(hidden_strengths)
    {
      unique_angle: "독특한 역량 조합으로 차별화",
      competitors_blindspot: "일반적이지 않은 강점 보유",
      unexpected_strengths: hidden_strengths[:unique_combinations] || [],
      future_value: "지속적 성장 가능성",
      cultural_amplifiers: [ "적응력", "학습능력" ]
    }
  end
end
