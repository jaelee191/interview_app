class UnifiedOntologyService
  attr_reader :job_analysis, :user_profile
  
  def initialize(job_analysis_id, user_profile_id = nil)
    @job_analysis = JobAnalysis.find(job_analysis_id)
    @user_profile = user_profile_id ? UserProfile.find(user_profile_id) : nil
  end
  
  def perform_analysis
    Rails.logger.info "Starting unified ontology analysis..."
    
    # 1. 각 온톨로지 구축
    applicant_graph = build_applicant_ontology
    job_graph = build_job_ontology  
    company_graph = build_company_ontology
    
    # 2. 매칭 수행
    matching_result = perform_matching(applicant_graph, job_graph, company_graph)
    
    # 3. 결과 저장 및 반환
    save_analysis_result(applicant_graph, job_graph, company_graph, matching_result)
  end
  
  private
  
  def build_applicant_ontology
    return {} unless @user_profile
    
    {
      id: "applicant_#{@user_profile.id}",
      name: @user_profile.name,
      skills: extract_skills(@user_profile),
      experiences: extract_experiences(@user_profile),
      education: @user_profile.education,
      achievements: @user_profile.achievements,
      competencies: derive_competencies(@user_profile)
    }
  end
  
  def build_job_ontology
    {
      id: "job_#{@job_analysis.id}",
      position: @job_analysis.position,
      required_skills: @job_analysis.required_skills || [],
      keywords: @job_analysis.keywords || [],
      responsibilities: extract_responsibilities,
      qualifications: extract_qualifications,
      company_values: @job_analysis.company_values || []
    }
  end
  
  def build_company_ontology
    {
      id: "company_#{@job_analysis.company_name}",
      name: @job_analysis.company_name,
      industry: detect_industry(@job_analysis.company_name),
      culture: extract_company_culture,
      recent_news: fetch_recent_news,
      market_position: analyze_market_position
    }
  end
  
  def perform_matching(applicant, job, company)
    {
      overall_score: calculate_overall_score(applicant, job, company),
      skill_match: match_skills(applicant[:skills], job[:required_skills]),
      experience_match: match_experience(applicant[:experiences], job[:responsibilities]),
      culture_fit: calculate_culture_fit(applicant, company),
      growth_potential: calculate_growth_potential(applicant, job),
      recommendations: generate_recommendations(applicant, job, company)
    }
  end
  
  def extract_skills(profile)
    skills = []
    
    # technical_skills JSONB에서 추출
    if profile.technical_skills.present?
      skills += profile.technical_skills.is_a?(String) ? 
                JSON.parse(profile.technical_skills) : 
                profile.technical_skills
    end
    
    # projects에서 기술 추출
    if profile.projects.present?
      projects = profile.projects.is_a?(String) ? 
                 JSON.parse(profile.projects) : 
                 profile.projects
      projects.each do |project|
        skills += extract_skills_from_text(project['description']) if project['description']
      end
    end
    
    skills.uniq
  end
  
  def extract_experiences(profile)
    experiences = []
    
    if profile.career_history.present?
      careers = profile.career_history.is_a?(String) ? 
                JSON.parse(profile.career_history) : 
                profile.career_history
      experiences = careers.map do |career|
        {
          company: career['company'],
          position: career['position'],
          duration: career['duration'],
          achievements: career['achievements']
        }
      end
    end
    
    experiences
  end
  
  def extract_skills_from_text(text)
    # 간단한 기술 추출 로직 (향후 NLP 개선 가능)
    tech_keywords = ['Python', 'Java', 'JavaScript', 'React', 'Node.js', 'SQL', 
                     'AWS', 'Docker', 'Kubernetes', 'Machine Learning', 'AI',
                     'Spring', 'Django', 'Rails', 'Vue', 'Angular']
    
    found_skills = []
    tech_keywords.each do |keyword|
      found_skills << keyword if text.downcase.include?(keyword.downcase)
    end
    found_skills
  end
  
  def derive_competencies(profile)
    competencies = []
    
    # 경력에서 역량 도출
    if profile.career_history.present?
      careers = profile.career_history.is_a?(String) ? 
                JSON.parse(profile.career_history) : 
                profile.career_history
      careers.each do |career|
        competencies << "리더십" if career['position']&.include?("팀장") || 
                                    career['position']&.include?("매니저")
        competencies << "프로젝트 관리" if career['position']&.include?("PM")
      end
    end
    
    competencies.uniq
  end
  
  def extract_responsibilities
    return [] unless @job_analysis.analysis_result.present?
    
    # analysis_result에서 주요 업무 추출
    result = @job_analysis.analysis_result.is_a?(String) ? 
             JSON.parse(@job_analysis.analysis_result) : 
             @job_analysis.analysis_result
    
    result['responsibilities'] || []
  end
  
  def extract_qualifications
    return [] unless @job_analysis.analysis_result.present?
    
    result = @job_analysis.analysis_result.is_a?(String) ? 
             JSON.parse(@job_analysis.analysis_result) : 
             @job_analysis.analysis_result
    
    result['qualifications'] || []
  end
  
  def detect_industry(company_name)
    # 간단한 산업 분류 (향후 API 연동 가능)
    case company_name.downcase
    when /tech|소프트|it|개발/
      "IT/소프트웨어"
    when /금융|은행|보험|증권/
      "금융"
    when /제조|공장|생산/
      "제조업"
    when /유통|리테일|커머스/
      "유통/커머스"
    else
      "기타"
    end
  end
  
  def extract_company_culture
    # 회사 문화 키워드 추출
    @job_analysis.company_values || []
  end
  
  def fetch_recent_news
    # 최근 뉴스 요약 (실제로는 크롤링 서비스 연동)
    []
  end
  
  def analyze_market_position
    # 시장 포지션 분석
    "성장기업"
  end
  
  def calculate_overall_score(applicant, job, company)
    skill_score = match_skills(applicant[:skills], job[:required_skills])[:score]
    exp_score = match_experience(applicant[:experiences], job[:responsibilities])[:score]
    culture_score = calculate_culture_fit(applicant, company)[:score]
    
    # 가중 평균
    (skill_score * 0.4 + exp_score * 0.4 + culture_score * 0.2).round
  end
  
  def match_skills(user_skills, required_skills)
    return { score: 0, matched: [], missing: required_skills } if user_skills.blank?
    
    user_skills_lower = user_skills.map(&:downcase)
    required_skills_lower = required_skills.map(&:downcase)
    
    matched = user_skills_lower & required_skills_lower
    missing = required_skills_lower - user_skills_lower
    
    score = required_skills.empty? ? 50 : (matched.size.to_f / required_skills.size * 100).round
    
    {
      score: score,
      matched: matched,
      missing: missing,
      additional: user_skills_lower - required_skills_lower
    }
  end
  
  def match_experience(user_experiences, job_responsibilities)
    return { score: 50, details: "경력 정보 없음" } if user_experiences.blank?
    
    # 경력 연차 계산
    total_months = 0
    user_experiences.each do |exp|
      if exp[:duration]
        # "2020.01 - 2022.12" 형식 파싱
        dates = exp[:duration].split('-').map(&:strip)
        if dates.size == 2
          begin
            start_date = Date.parse(dates[0].gsub('.', '-'))
            end_date = dates[1] == "현재" ? Date.today : Date.parse(dates[1].gsub('.', '-'))
            total_months += ((end_date - start_date).to_i / 30)
          rescue
            total_months += 12 # 파싱 실패시 기본값
          end
        end
      end
    end
    
    years = total_months / 12.0
    
    # 경력 점수 계산
    score = case years
            when 0..1 then 60
            when 1..3 then 70
            when 3..5 then 80
            when 5..10 then 90
            else 95
            end
    
    {
      score: score,
      years: years.round(1),
      details: "#{years.round(1)}년 경력"
    }
  end
  
  def calculate_culture_fit(applicant, company)
    # 문화 적합도 계산 (간단한 버전)
    base_score = 70
    
    # 회사 가치와 지원자 특성 매칭
    if applicant[:achievements]&.include?("팀") || applicant[:competencies]&.include?("리더십")
      base_score += 10
    end
    
    {
      score: [base_score, 100].min,
      factors: ["협업 경험", "리더십 역량"]
    }
  end
  
  def calculate_growth_potential(applicant, job)
    # 성장 잠재력 평가
    factors = []
    score = 60
    
    # 학력 체크
    if applicant[:education]&.include?("석사") || applicant[:education]&.include?("박사")
      score += 10
      factors << "고급 학위"
    end
    
    # 다양한 기술 스택
    if applicant[:skills]&.size.to_i > 5
      score += 10
      factors << "다양한 기술 역량"
    end
    
    # 프로젝트 경험
    if applicant[:experiences]&.size.to_i > 2
      score += 10
      factors << "풍부한 프로젝트 경험"
    end
    
    {
      score: [score, 100].min,
      factors: factors
    }
  end
  
  def generate_recommendations(applicant, job, company)
    recommendations = []
    
    # 스킬 갭 분석
    skill_match = match_skills(applicant[:skills], job[:required_skills])
    if skill_match[:missing].any?
      recommendations << {
        type: "skill_gap",
        priority: "high",
        message: "다음 기술을 보완하면 경쟁력이 높아집니다: #{skill_match[:missing].join(', ')}"
      }
    end
    
    # 경험 보완
    exp_match = match_experience(applicant[:experiences], job[:responsibilities])
    if exp_match[:score] < 70
      recommendations << {
        type: "experience",
        priority: "medium",
        message: "관련 프로젝트 경험을 더 구체적으로 어필하세요"
      }
    end
    
    # 강점 활용
    if skill_match[:additional] && skill_match[:additional].any?
      recommendations << {
        type: "strength",
        priority: "low",
        message: "추가 보유 기술(#{skill_match[:additional].first(3).join(', ')})을 차별화 포인트로 활용하세요"
      }
    end
    
    recommendations
  end
  
  def save_analysis_result(applicant_graph, job_graph, company_graph, matching_result)
    analysis = OntologyAnalysis.find_or_initialize_by(
      job_analysis: @job_analysis,
      user_profile: @user_profile
    )
    
    analysis.update!(
      applicant_graph: applicant_graph,
      job_graph: job_graph,
      company_graph: company_graph,
      matching_result: matching_result,
      analysis_status: 'completed',
      analyzed_at: Time.current
    )
    
    analysis
  end
  
  def generate_visualization_data(matching_result)
    {
      nodes: generate_nodes,
      links: generate_links(matching_result),
      metrics: {
        overall_score: matching_result[:overall_score],
        skill_match: matching_result[:skill_match][:score],
        experience_match: matching_result[:experience_match][:score],
        culture_fit: matching_result[:culture_fit][:score]
      }
    }
  end
  
  def generate_nodes
    nodes = []
    
    # 지원자 노드
    if @user_profile
      nodes << {
        id: "applicant",
        label: @user_profile.name || "지원자",
        type: "applicant",
        size: 30
      }
      
      # 스킬 노드들
      skills = extract_skills(@user_profile)
      skills.each do |skill|
        nodes << {
          id: "skill_#{skill}",
          label: skill,
          type: "skill",
          size: 20
        }
      end
    end
    
    # 직무 노드
    nodes << {
      id: "job",
      label: @job_analysis.position,
      type: "job",
      size: 30
    }
    
    # 회사 노드
    nodes << {
      id: "company",
      label: @job_analysis.company_name,
      type: "company",
      size: 35
    }
    
    nodes
  end
  
  def generate_links(matching_result)
    links = []
    
    if @user_profile
      # 지원자 -> 직무 연결
      links << {
        source: "applicant",
        target: "job",
        value: matching_result[:overall_score],
        type: "match"
      }
      
      # 지원자 -> 회사 연결
      links << {
        source: "applicant",
        target: "company",
        value: matching_result[:culture_fit][:score],
        type: "culture"
      }
      
      # 스킬 연결
      skills = extract_skills(@user_profile)
      skills.each do |skill|
        links << {
          source: "applicant",
          target: "skill_#{skill}",
          value: 10,
          type: "has_skill"
        }
        
        # 직무에서 요구하는 스킬인 경우
        if @job_analysis.required_skills&.map(&:downcase)&.include?(skill.downcase)
          links << {
            source: "skill_#{skill}",
            target: "job",
            value: 20,
            type: "required"
          }
        end
      end
    end
    
    links
  end
end