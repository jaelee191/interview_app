class IntelligentCoverLetterGeneratorService
  def initialize(user_profile, job_posting_url_or_data, company_name)
    @user_profile = user_profile
    @job_posting = job_posting_url_or_data
    @company_name = company_name
    @parallel_service = ParallelOpenaiService.new(model: ENV['OPENAI_MODEL'] || 'gpt-4o')
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
    HiddenStrengthDiscoveryService.new(@user_profile).discover_hidden_strengths
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
    ContextualMatchingEngineService.new(
      company_context,
      hidden_strengths,
      job_requirements
    ).generate_contextual_insights
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
    return draft unless ENV['OPENAI_API_KEY'].present?
    
    prompt = <<~PROMPT
      다음은 AI가 생성한 자기소개서 초안입니다. 
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
      system_prompt: '당신은 채용 전문가이자 자기소개서 작성 전문가입니다.',
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
  
  def call_openai_api(prompt, model: 'gpt-4o')
    require 'net/http'
    require 'json'
    
    uri = URI('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{ENV['OPENAI_API_KEY']}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      model: model,
      messages: [
        { 
          role: 'system', 
          content: '당신은 채용 전문가이자 자기소개서 작성 전문가입니다. 지원자의 강점을 기업 니즈와 연결하여 설득력 있는 자기소개서를 작성합니다.' 
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.8,
      max_tokens: 2000
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
    
    section = ["[기업 과제 해결 역량]"]
    
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
    
    section = ["[차별화된 역량]"]
    
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
    section = ["[즉시 기여 가능한 영역]"]
    
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
end