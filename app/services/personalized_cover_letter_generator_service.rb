require 'net/http'
require 'json'

# 개인화된 AI 자소서 생성 서비스
# AI 탐지 회피 기술과 지식 그래프 기반 개인화 적용
class PersonalizedCoverLetterGeneratorService
  OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions'
  
  # AI 탐지 회피를 위한 패턴 라이브러리
  WRITING_PATTERNS = {
    sentence_starters: [
      "제가 생각하기에", "개인적으로", "경험상", "돌이켜보면", 
      "그 당시", "처음에는", "시간이 지나며", "결과적으로"
    ],
    connectors: [
      "그러나", "하지만", "그럼에도", "덕분에", "이를 통해",
      "그 과정에서", "특히", "무엇보다", "이러한 경험은"
    ],
    natural_imperfections: [
      "사실", "솔직히", "어떻게 보면", "그래서인지",
      "아마도", "분명", "확실히", "물론"
    ]
  }
  
  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    @model = ENV['OPENAI_MODEL'] || 'gpt-4.1'
  end
  
  # 지식 그래프 구축 (경험 구조화)
  def build_knowledge_graph(experiences)
    graph = {
      skills: extract_skills(experiences),
      achievements: extract_achievements(experiences),
      challenges: extract_challenges(experiences),
      learnings: extract_learnings(experiences),
      connections: find_experience_connections(experiences)
    }
    
    # 경험 간 관계 분석
    graph[:relationships] = analyze_relationships(graph)
    graph
  end
  
  # AI 탐지 회피 전략 적용
  def apply_anti_detection_strategies(text)
    # 1. 문장 길이 다양화
    text = vary_sentence_length(text)
    
    # 2. 자연스러운 불완전성 추가
    text = add_natural_imperfections(text)
    
    # 3. 개인적 어투 강화
    text = enhance_personal_tone(text)
    
    # 4. 문단 구조 자연스럽게 변경
    text = naturalize_paragraph_structure(text)
    
    text
  end
  
  # 맥락 기반 자소서 생성
  def generate_contextual_cover_letter(job_analysis, personal_data, company_context)
    # 1. 개인 경험 지식 그래프 구축
    knowledge_graph = build_knowledge_graph(personal_data[:experiences])
    
    # 2. 기업 맥락과 개인 경험 매칭
    matched_experiences = match_experiences_to_context(
      knowledge_graph,
      job_analysis,
      company_context
    )
    
    # 3. 스토리텔링 구조 설계
    story_structure = design_story_structure(
      matched_experiences,
      job_analysis[:key_requirements],
      company_context[:current_situation]
    )
    
    # 4. AI로 초안 생성
    draft = generate_draft_with_ai(
      story_structure,
      personal_data,
      job_analysis,
      company_context
    )
    
    # 5. AI 탐지 회피 처리
    humanized_draft = apply_anti_detection_strategies(draft)
    
    # 6. 최종 검토 및 개선
    final_version = final_review_and_polish(humanized_draft, job_analysis)
    
    {
      success: true,
      cover_letter: final_version,
      metadata: {
        key_points_covered: extract_key_points(final_version, job_analysis),
        uniqueness_score: calculate_uniqueness_score(final_version),
        ai_detection_risk: assess_ai_detection_risk(final_version),
        personalization_level: calculate_personalization_level(final_version, personal_data)
      },
      suggestions: generate_improvement_suggestions(final_version, job_analysis)
    }
  end
  
  private
  
  def extract_skills(experiences)
    skills = []
    experiences.each do |exp|
      # 경험에서 스킬 추출 로직
      if exp[:description]
        # 기술 스킬 패턴
        tech_skills = exp[:description].scan(/(?:Python|Java|React|SQL|AWS|Docker|Git|\w+\.js)/i)
        skills.concat(tech_skills)
        
        # 소프트 스킬 패턴
        soft_skills = []
        soft_skills << "리더십" if exp[:description].match?(/팀.*리드|주도|이끌/)
        soft_skills << "문제해결" if exp[:description].match?(/해결|개선|최적화/)
        soft_skills << "소통" if exp[:description].match?(/협업|소통|커뮤니케이션/)
        skills.concat(soft_skills)
      end
    end
    skills.uniq
  end
  
  def extract_achievements(experiences)
    achievements = []
    experiences.each do |exp|
      if exp[:description]
        # 성과 패턴 매칭
        if exp[:description].match?(/(?:\d+%.*향상|개선|증가|감소|달성|수상|1위)/)
          achievements << {
            experience: exp[:title],
            achievement: exp[:description][/(?:\d+%.*(?:향상|개선|증가|감소)|.*(?:달성|수상|1위)[^。]*)/],
            impact: categorize_impact(exp[:description])
          }
        end
      end
    end
    achievements
  end
  
  def extract_challenges(experiences)
    experiences.select { |exp| 
      exp[:description]&.match?(/문제|어려움|도전|극복|해결/)
    }.map { |exp|
      {
        title: exp[:title],
        challenge: exp[:description][/.*(?:문제|어려움|도전)[^。]*/],
        solution: exp[:description][/.*(?:극복|해결|개선)[^。]*/]
      }
    }
  end
  
  def extract_learnings(experiences)
    experiences.map { |exp|
      next unless exp[:description]
      
      learning = exp[:description][/.*(?:배웠|깨달|느꼈|경험했)[^。]*/]
      next unless learning
      
      {
        experience: exp[:title],
        learning: learning,
        applicable_to: identify_application_areas(learning)
      }
    }.compact
  end
  
  def find_experience_connections(experiences)
    connections = []
    
    experiences.each_with_index do |exp1, i|
      experiences[(i+1)..-1].each do |exp2|
        similarity = calculate_similarity(exp1, exp2)
        if similarity > 0.3
          connections << {
            from: exp1[:title],
            to: exp2[:title],
            connection_type: identify_connection_type(exp1, exp2),
            strength: similarity
          }
        end
      end
    end
    
    connections
  end
  
  def vary_sentence_length(text)
    sentences = text.split(/(?<=[.!?])\s+/)
    varied_sentences = []
    
    sentences.each_with_index do |sentence, i|
      # 인접한 문장과 길이 차이를 두기
      if i > 0 && sentence.length > 100 && sentences[i-1].length > 100
        # 긴 문장이 연속되면 중간을 나누기
        parts = sentence.split(/,\s+/)
        if parts.length > 2
          mid = parts.length / 2
          varied_sentences << parts[0..mid].join(", ") + "."
          varied_sentences << parts[(mid+1)..-1].join(", ")
        else
          varied_sentences << sentence
        end
      else
        varied_sentences << sentence
      end
    end
    
    varied_sentences.join(" ")
  end
  
  def add_natural_imperfections(text)
    sentences = text.split(/(?<=[.!?])\s+/)
    
    sentences.map.with_index { |sentence, i|
      # 20% 확률로 자연스러운 표현 추가
      if rand < 0.2 && i > 0
        starter = WRITING_PATTERNS[:natural_imperfections].sample
        "#{starter} #{sentence.downcase}"
      elsif rand < 0.15
        # 연결어 추가
        connector = WRITING_PATTERNS[:connectors].sample
        "#{connector} #{sentence.downcase}"
      else
        sentence
      end
    }.join(" ")
  end
  
  def enhance_personal_tone(text)
    # 1인칭 표현 강화
    text = text.gsub(/수행했습니다/, ["수행했습니다", "진행했습니다", "담당했습니다"].sample)
    text = text.gsub(/경험했습니다/, ["경험했습니다", "겪었습니다", "체험했습니다"].sample)
    
    # 감정 표현 추가
    text = text.gsub(/성공적으로/, ["성공적으로", "뿌듯하게", "만족스럽게", "의미있게"].sample)
    text = text.gsub(/완료했습니다/, ["완료했습니다", "마무리했습니다", "끝냈습니다"].sample)
    
    text
  end
  
  def naturalize_paragraph_structure(text)
    paragraphs = text.split("\n\n")
    
    # 문단 길이 다양화
    naturalized = paragraphs.map { |para|
      sentences = para.split(/(?<=[.!?])\s+/)
      
      # 3-5문장 사이로 조정
      if sentences.length > 5
        # 긴 문단은 나누기
        mid = sentences.length / 2
        [sentences[0...mid].join(" "), sentences[mid..-1].join(" ")]
      elsif sentences.length < 2 && para.length > 200
        # 너무 긴 단일 문장은 나누기
        parts = para.split(/,\s+/)
        if parts.length > 3
          [parts[0..1].join(", ") + ".", parts[2..-1].join(", ")]
        else
          para
        end
      else
        para
      end
    }.flatten
    
    naturalized.join("\n\n")
  end
  
  def match_experiences_to_context(knowledge_graph, job_analysis, company_context)
    matched = []
    
    # 기업이 원하는 핵심 역량과 매칭
    job_analysis[:key_requirements]&.each do |requirement|
      # 지식 그래프에서 관련 경험 찾기
      relevant_skills = knowledge_graph[:skills].select { |skill|
        skill.downcase.include?(requirement.downcase) ||
        requirement.downcase.include?(skill.downcase)
      }
      
      relevant_achievements = knowledge_graph[:achievements].select { |ach|
        ach[:achievement]&.downcase&.include?(requirement.downcase)
      }
      
      if relevant_skills.any? || relevant_achievements.any?
        matched << {
          requirement: requirement,
          matching_skills: relevant_skills,
          matching_achievements: relevant_achievements,
          relevance_score: calculate_relevance_score(relevant_skills, relevant_achievements)
        }
      end
    end
    
    # 기업 상황과 연관된 경험 매칭
    if company_context[:current_challenges]
      knowledge_graph[:challenges].each do |challenge|
        if relates_to_company_situation?(challenge, company_context[:current_challenges])
          matched << {
            context: "company_challenge",
            experience: challenge,
            relevance: "high"
          }
        end
      end
    end
    
    matched.sort_by { |m| m[:relevance_score] || 1.0 }.reverse
  end
  
  def design_story_structure(matched_experiences, key_requirements, company_situation)
    {
      opening: {
        hook: generate_hook(company_situation),
        connection: "기업과 나의 연결점"
      },
      body: {
        main_experience: select_main_experience(matched_experiences),
        supporting_experiences: select_supporting_experiences(matched_experiences, 2),
        growth_narrative: "경험을 통한 성장 스토리"
      },
      conclusion: {
        future_contribution: "입사 후 기여 방안",
        alignment: "기업 가치관과의 일치"
      }
    }
  end
  
  def generate_draft_with_ai(story_structure, personal_data, job_analysis, company_context)
    prompt = build_generation_prompt(story_structure, personal_data, job_analysis, company_context)
    
    response = make_api_request(prompt)
    parse_response(response)[:content]
  end
  
  def build_generation_prompt(story_structure, personal_data, job_analysis, company_context)
    <<~PROMPT
      당신은 자기소개서 작성 전문가입니다. 다음 정보를 바탕으로 진정성 있고 차별화된 자기소개서를 작성해주세요.
      
      중요: AI가 작성한 것처럼 보이지 않도록 자연스럽고 인간적인 문체를 사용하세요.
      
      **지원자 정보**
      이름: #{personal_data[:name]}
      경력: #{personal_data[:career_years]}년
      핵심 경험: #{personal_data[:experiences]&.map { |e| e[:title] }&.join(", ")}
      
      **지원 회사 및 직무**
      회사: #{job_analysis[:company_name]}
      직무: #{job_analysis[:position]}
      핵심 요구사항: #{job_analysis[:key_requirements]&.join(", ")}
      
      **기업 현재 상황**
      #{company_context[:current_situation]}
      
      **스토리 구조**
      1. 도입부: #{story_structure[:opening][:hook]}
      2. 본문:
         - 핵심 경험: #{story_structure[:body][:main_experience]}
         - 보조 경험: #{story_structure[:body][:supporting_experiences]}
      3. 마무리: #{story_structure[:conclusion][:future_contribution]}
      
      **작성 가이드라인**
      
      1. 자연스러운 문체:
         - 문장 길이를 다양하게 (15-40자)
         - 간혹 불완전한 표현 사용 ("사실", "솔직히", "그래서인지")
         - 개인적 감정과 깨달음 포함
      
      2. 구체적 경험 서술:
         - STAR 기법 활용하되 딱딱하지 않게
         - 숫자와 성과를 자연스럽게 녹여내기
         - 실패와 배움도 솔직하게 포함
      
      3. 차별화 포인트:
         - 남들과 다른 독특한 관점 제시
         - 기업의 현재 상황과 연결
         - 미래 기여 방안 구체적으로
      
      4. AI 탐지 회피:
         - 완벽한 문법 피하기
         - 때로는 구어체 사용
         - 개인적 일화나 감정 포함
         - 반복적 패턴 피하기
      
      자기소개서를 작성해주세요. (800-1000자)
    PROMPT
  end
  
  def final_review_and_polish(draft, job_analysis)
    # 키워드 확인 및 보강
    enhanced = ensure_keywords_included(draft, job_analysis[:keywords])
    
    # 자연스러운 마무리 처리
    polished = polish_transitions(enhanced)
    
    # 최종 길이 조정
    adjusted = adjust_length(polished, 800, 1000)
    
    adjusted
  end
  
  def extract_key_points(text, job_analysis)
    points = []
    
    job_analysis[:key_requirements]&.each do |req|
      if text.include?(req) || text.match?(/#{Regexp.escape(req)}/i)
        points << req
      end
    end
    
    points
  end
  
  def calculate_uniqueness_score(text)
    # 일반적인 자소서 표현 패턴
    common_patterns = [
      "성장했습니다", "배웠습니다", "노력하겠습니다", 
      "기여하겠습니다", "열정을 가지고", "최선을 다해"
    ]
    
    common_count = common_patterns.count { |pattern| text.include?(pattern) }
    
    # 독특한 표현이나 구체적 수치 확인
    unique_indicators = text.scan(/\d+[%명개]/)
    personal_stories = text.scan(/제가|저는|저의/).length
    
    base_score = 70
    base_score -= (common_count * 5)
    base_score += (unique_indicators.length * 3)
    base_score += ([personal_stories, 10].min * 2)
    
    [base_score, 100].min
  end
  
  def assess_ai_detection_risk(text)
    risk_factors = {
      perfect_grammar: assess_grammar_perfection(text),
      repetitive_patterns: check_repetitive_patterns(text),
      lack_of_personality: check_personality_indicators(text),
      uniform_sentence_length: check_sentence_variety(text)
    }
    
    risk_score = risk_factors.values.sum / risk_factors.length.to_f
    
    {
      risk_level: case risk_score
                  when 0..30 then "낮음"
                  when 31..60 then "중간"
                  else "높음"
                  end,
      risk_score: risk_score,
      factors: risk_factors
    }
  end
  
  def calculate_personalization_level(text, personal_data)
    personal_references = 0
    
    # 개인 경험 언급 확인
    personal_data[:experiences]&.each do |exp|
      personal_references += 1 if text.include?(exp[:title])
    end
    
    # 개인적 표현 확인
    personal_expressions = text.scan(/제가 느낀|개인적으로|저에게는|제 경험상/).length
    
    score = (personal_references * 20) + (personal_expressions * 10)
    [score, 100].min
  end
  
  def generate_improvement_suggestions(cover_letter, job_analysis)
    suggestions = []
    
    # 키워드 부족 확인
    missing_keywords = job_analysis[:keywords]&.reject { |kw| 
      cover_letter.include?(kw) 
    }
    
    if missing_keywords&.any?
      suggestions << "다음 키워드를 자연스럽게 포함시켜보세요: #{missing_keywords.join(", ")}"
    end
    
    # 문장 길이 다양성 확인
    sentences = cover_letter.split(/[.!?]/)
    avg_length = sentences.map(&:length).sum / sentences.length.to_f
    
    if sentences.map(&:length).uniq.length < sentences.length * 0.5
      suggestions << "문장 길이를 더 다양하게 만들어 자연스러움을 높이세요"
    end
    
    # 구체적 수치 부족
    if cover_letter.scan(/\d+/).length < 3
      suggestions << "구체적인 성과나 숫자를 더 포함시켜 신뢰도를 높이세요"
    end
    
    suggestions
  end
  
  # Helper methods
  
  def categorize_impact(description)
    case description
    when /\d{2,}%|배 이상|대폭/
      "high"
    when /개선|향상|증가/
      "medium"
    else
      "low"
    end
  end
  
  def identify_application_areas(learning)
    areas = []
    areas << "문제해결" if learning.match?(/해결|극복/)
    areas << "팀워크" if learning.match?(/협업|팀|함께/)
    areas << "리더십" if learning.match?(/리드|이끌|주도/)
    areas << "혁신" if learning.match?(/새로운|혁신|창의/)
    areas
  end
  
  def calculate_similarity(exp1, exp2)
    return 0 unless exp1[:description] && exp2[:description]
    
    # 간단한 자카드 유사도 계산
    words1 = exp1[:description].split.map(&:downcase).uniq
    words2 = exp2[:description].split.map(&:downcase).uniq
    
    intersection = words1 & words2
    union = words1 | words2
    
    intersection.length.to_f / union.length
  end
  
  def identify_connection_type(exp1, exp2)
    if exp1[:period] && exp2[:period]
      return "sequential" if exp1[:period] < exp2[:period]
      return "parallel" if exp1[:period] == exp2[:period]
    end
    
    "thematic"
  end
  
  def calculate_relevance_score(skills, achievements)
    skill_score = skills.length * 0.3
    achievement_score = achievements.length * 0.7
    
    (skill_score + achievement_score) / 2.0
  end
  
  def relates_to_company_situation?(challenge, company_challenges)
    return false unless challenge[:challenge] && company_challenges
    
    company_challenges.any? { |cc|
      challenge[:challenge].downcase.include?(cc.downcase) ||
      cc.downcase.include?(challenge[:challenge].downcase)
    }
  end
  
  def generate_hook(company_situation)
    return "기업의 새로운 도전에 함께하고 싶습니다" unless company_situation
    
    if company_situation.include?("성장")
      "급성장하는 #{company_situation}에 기여하고 싶습니다"
    elsif company_situation.include?("혁신")
      "혁신의 최전선에서 함께 도전하고 싶습니다"
    else
      "#{company_situation}라는 비전에 깊이 공감합니다"
    end
  end
  
  def select_main_experience(matched_experiences)
    return "핵심 프로젝트 경험" unless matched_experiences&.any?
    
    # 가장 관련성 높은 경험 선택
    best_match = matched_experiences.max_by { |m| m[:relevance_score] || 0 }
    best_match[:matching_achievements]&.first&.dig(:experience) || "주요 경험"
  end
  
  def select_supporting_experiences(matched_experiences, count)
    return [] unless matched_experiences&.any?
    
    matched_experiences[1..count].map { |m|
      m[:matching_achievements]&.first&.dig(:experience) || m[:requirement]
    }.compact
  end
  
  def ensure_keywords_included(text, keywords)
    return text unless keywords
    
    missing_keywords = keywords.reject { |kw| text.include?(kw) }
    
    if missing_keywords.any?
      # 자연스럽게 키워드 삽입
      insertion_point = text.length * 0.7
      before = text[0...insertion_point]
      after = text[insertion_point..-1]
      
      keyword_sentence = "또한 #{missing_keywords.first(2).join("과 ")} 역량을 바탕으로 "
      text = before + keyword_sentence + after
    end
    
    text
  end
  
  def polish_transitions(text)
    # 문단 간 전환을 자연스럽게
    paragraphs = text.split("\n\n")
    
    transitions = [
      "이러한 경험을 통해",
      "더 나아가",
      "이를 바탕으로",
      "결과적으로"
    ]
    
    polished_paragraphs = paragraphs.map.with_index { |para, i|
      if i > 0 && i < paragraphs.length - 1 && !para.match?(/^(이러한|더 나아가|이를|결과)/)
        "#{transitions[i % transitions.length]} #{para.downcase}"
      else
        para
      end
    }
    
    polished_paragraphs.join("\n\n")
  end
  
  def adjust_length(text, min_length, max_length)
    current_length = text.length
    
    if current_length < min_length
      # 내용 보강
      text += "\n\n입사 후에는 제가 쌓아온 경험과 역량을 바탕으로 팀과 회사의 성장에 실질적으로 기여하고 싶습니다."
    elsif current_length > max_length
      # 축약
      sentences = text.split(/(?<=[.!?])\s+/)
      while text.length > max_length && sentences.length > 10
        sentences.delete_at(sentences.length / 2)
        text = sentences.join(" ")
      end
    end
    
    text
  end
  
  def assess_grammar_perfection(text)
    # 완벽한 문법 사용 여부 체크
    imperfections = text.scan(/그래서인지|아마도|사실|솔직히|어떻게 보면/)
    imperfections.any? ? 20 : 80
  end
  
  def check_repetitive_patterns(text)
    sentences = text.split(/[.!?]/)
    starts = sentences.map { |s| s.strip.split.first }
    
    # 문장 시작 패턴의 다양성
    unique_ratio = starts.uniq.length.to_f / starts.length
    unique_ratio < 0.7 ? 70 : 30
  end
  
  def check_personality_indicators(text)
    # 개인적 표현 확인
    personal_expressions = text.scan(/제가|저는|저에게|개인적으로|느꼈|생각했/)
    personal_expressions.length > 5 ? 20 : 60
  end
  
  def check_sentence_variety(text)
    sentences = text.split(/[.!?]/)
    lengths = sentences.map(&:length)
    
    return 50 if lengths.empty?
    
    std_dev = Math.sqrt(lengths.map { |l| (l - lengths.sum.to_f / lengths.length) ** 2 }.sum / lengths.length)
    
    std_dev > 20 ? 20 : 60
  end
  
  def make_api_request(prompt)
    uri = URI(OPENAI_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      model: @model,
      messages: [
        {
          role: 'system',
          content: '당신은 인간적이고 진정성 있는 자기소개서를 작성하는 전문가입니다. AI가 작성한 것처럼 보이지 않도록 자연스럽고 개인적인 문체를 사용하세요.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.85,  # 더 창의적이고 자연스러운 결과
      max_tokens: 2000
    }.to_json
    
    response = http.request(request)
    JSON.parse(response.body)
  end
  
  def parse_response(response)
    if response['error']
      { error: response['error']['message'] }
    elsif response['choices'] && response['choices'].first
      {
        success: true,
        content: response['choices'].first['message']['content'],
        usage: response['usage']
      }
    else
      { error: '예상치 못한 응답 형식입니다' }
    end
  end
end