require 'net/http'
require 'json'

class InteractiveCoverLetterService
  OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions'
  
  STEPS = [
    { id: 'company_research', title: '기업 조사', icon: '🏢', questions: 3 },
    { id: 'self_introduction', title: '자기소개', icon: '👤', questions: 3 },
    { id: 'motivation', title: '지원동기', icon: '🎯', questions: 2 },
    { id: 'experience', title: '핵심 경험', icon: '💼', questions: 3 },
    { id: 'strengths', title: '강점 및 역량', icon: '💪', questions: 2 },
    { id: 'vision', title: '입사 후 포부', icon: '🚀', questions: 2 },
    { id: 'review', title: '최종 검토', icon: '✅', questions: 1 }
  ]
  
  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    @model = ENV['OPENAI_MODEL'] || 'gpt-4o'
    @conversation_history = []
  end
  
  def start_conversation(company_name, position)
    {
      current_step: 'company_research',
      company_name: company_name,
      position: position,
      content: {},
      messages: [
        {
          role: 'assistant',
          content: greeting_message(company_name, position)
        }
      ]
    }
  end
  
  def process_message(session_data, user_message)
    return { error: 'Session data is missing' } unless session_data
    return { error: 'API key is not configured' } unless @api_key
    
    current_step = session_data['current_step'] || session_data[:current_step]
    session_data['question_count'] ||= {}
    session_data['question_count'][current_step] ||= 0
    session_data['question_count'][current_step] += 1
    
    # 전체 대화 컨텍스트 구성
    @conversation_history = build_conversation_history(session_data)
    
    # AI에게 사용자 응답 처리 요청 (향상된 프롬프트)
    ai_response = get_enhanced_ai_response(
      session_data,
      user_message,
      current_step
    )
    
    # 현재 단계의 내용 저장
    session_data['content'] ||= {}
    current_content = session_data['content'][current_step] || ""
    session_data['content'][current_step] = current_content + "\n" + user_message if current_content.present?
    session_data['content'][current_step] ||= user_message
    
    # 단계별 질문 수 체크 후 다음 단계로 이동
    current_step_info = STEPS.find { |s| s[:id] == current_step }
    max_questions = current_step_info[:questions] || 3
    
    if session_data['question_count'][current_step] >= max_questions || ai_response.include?("다음 단계")
      next_step = get_next_step(current_step)
      session_data['current_step'] = next_step
      session_data['question_count'][next_step] = 0
      
      if next_step == 'review'
        # 최종 검토 단계: 전체 자소서 생성
        final_content = generate_enhanced_cover_letter(session_data)
        session_data['final_content'] = final_content
        ai_response = final_review_message(final_content)
      else
        # 다음 단계 안내 메시지 추가
        ai_response += get_step_transition_message(next_step)
      end
    end
    
    # 대화 기록 업데이트
    session_data['messages'] ||= []
    session_data['messages'] << { 'role' => 'user', 'content' => user_message }
    session_data['messages'] << { 'role' => 'assistant', 'content' => ai_response }
    
    {
      session_data: session_data,
      response: ai_response,
      current_step: session_data['current_step'],
      progress: calculate_progress(session_data['current_step'])
    }
  rescue StandardError => e
    Rails.logger.error "Interactive cover letter error: #{e.message}"
    {
      session_data: session_data,
      response: "죄송합니다. 일시적인 오류가 발생했습니다. 다시 시도해주세요.",
      current_step: session_data['current_step'],
      progress: calculate_progress(session_data['current_step'])
    }
  end
  
  private
  
  def greeting_message(company_name, position)
    <<~MESSAGE
      안녕하세요! #{company_name} #{position} 직무 자기소개서 작성을 도와드리겠습니다. 🎯
      
      저는 AI 자기소개서 전문 코치입니다. 수천 건의 합격 자소서를 분석한 데이터를 바탕으로
      맞춤형 질문과 조언을 드리겠습니다.
      
      **📝 스마트 작성 프로세스 (7단계)**
      각 단계마다 2-3개의 핵심 질문을 통해 필요한 정보를 수집하고,
      실시간으로 피드백과 개선 제안을 드립니다.
      
      1. 🏢 **기업 조사** (3개 질문) - 기업 이해도 파악
      2. 👤 **자기소개** (3개 질문) - 핵심 역량 도출
      3. 🎯 **지원동기** (2개 질문) - 진정성 확보
      4. 💼 **핵심 경험** (3개 질문) - STAR 기법 적용
      5. 💪 **강점/역량** (2개 질문) - 직무 매칭
      6. 🚀 **입사 후 포부** (2개 질문) - 비전 제시
      7. ✅ **최종 검토** - AI 자동 완성
      
      **🏢 1단계: 기업 조사 시작**
      
      #{company_name}에 대해 얼마나 알고 계신가요? 
      
      💡 **첫 번째 질문:**
      #{company_name}의 주요 사업 분야와 최근 화제가 된 뉴스나 이슈를 아는 대로 말씀해주세요.
      (모르시는 부분은 제가 보완해드립니다)
    MESSAGE
  end
  
  def build_conversation_history(session_data)
    history = []
    messages = session_data['messages'] || []
    company_name = session_data['company_name'] || session_data[:company_name]
    
    # 시스템 프롬프트
    history << {
      role: 'system',
      content: "당신은 2025년 8월 기준 최신 기업 정보에 정통한 자기소개서 작성 코치입니다.
                #{company_name}의 최신 동향을 잘 알고 있으며, 구체적인 사실과 수치를 제공합니다.
                지원자가 최신 이슈를 물으면 반드시 구체적인 정보를 제공하세요.
                
                예시 (삼성전자):
                - 2025년 HBM4 개발 진행 중, 2026년 양산 목표
                - 2025년 7월 파운드리 2나노 GAA 공정 양산 시작
                - AI 반도체 'Mach-2' NPU 개발, 애플/구글과 협업
                - 2025년 스마트싱스 플랫폼 3억 디바이스 연결 달성
                
                답변은 구체적이고 최신 정보를 포함하되, 2000자 이내로 디테일하게 작성하세요.
                
                답변 구조:
                1. 핵심 이슈 3-5개를 카테고리별로 정리
                2. 각 이슈마다 구체적 날짜, 수치, 제품명 포함
                3. 업계 경쟁사와의 비교 관점 추가
                4. 마지막에 '💡 AI 인사이트:' 로 시작하는 2줄 분석 추가
                   (지원자가 이 정보를 어떻게 활용하면 좋을지 조언)"
    }
    
    # 기존 대화 내역 추가
    messages.last(10).each do |msg|
      history << {
        role: msg['role'] || msg[:role],
        content: msg['content'] || msg[:content]
      }
    end
    
    history
  end
  
  def get_enhanced_ai_response(session_data, user_message, current_step)
    company_name = session_data['company_name'] || session_data[:company_name]
    position = session_data['position'] || session_data[:position]
    question_count = session_data['question_count'][current_step] || 1
    
    # 컨텍스트 포함한 대화 이력
    messages = @conversation_history.dup
    
    # 현재 단계별 맞춤 프롬프트
    step_info = STEPS.find { |s| s[:id] == current_step }
    
    messages << {
      role: 'user',
      content: "#{user_message}\n\n[현재: #{step_info[:title]} 단계, #{question_count}/#{step_info[:questions]}번째 질문]"
    }
    
    response = make_enhanced_api_request(messages, current_step, question_count, step_info[:questions], company_name)
    
    if response[:success]
      response[:content]
    else
      "답변을 잘 받았습니다. 계속 진행해주세요."
    end
  end
  
  def get_step_transition_message(next_step)
    step_info = STEPS.find { |s| s[:id] == next_step }
    
    <<~MESSAGE
      
      
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      
      #{step_info[:icon]} **#{step_info[:title]} 단계로 넘어갑니다**
      
      이제 #{get_step_description(next_step)}에 대해 이야기해볼까요?
    MESSAGE
  end
  
  def get_step_description(step_id)
    descriptions = {
      'self_introduction' => '당신이 어떤 사람인지',
      'motivation' => '이 회사를 선택한 이유',
      'experience' => '관련된 핵심 경험들',
      'strengths' => '당신의 강점과 역량',
      'vision' => '입사 후 포부와 계획',
      'review' => '전체 내용 검토'
    }
    descriptions[step_id] || '다음 내용'
  end
  
  def get_ai_response(session_data, user_message, current_step)
    prompt = build_step_prompt(session_data, user_message, current_step)
    
    response = make_api_request(prompt, "자기소개서 작성 코치")
    parse_response(response)[:content]
  end
  
  def build_step_prompt(session_data, user_message, current_step)
    company_name = session_data['company_name'] || session_data[:company_name]
    position = session_data['position'] || session_data[:position]
    
    step_prompts = {
      'company_research' => <<~PROMPT,
        사용자가 #{company_name}에 대해 설명했습니다.
        
        사용자 답변: #{user_message}
        
        1. 사용자가 언급한 내용을 긍정적으로 평가하고 보완해주세요
        2. 추가로 알아두면 좋을 기업 정보를 간단히 제공하세요
        3. 다음 단계(자기소개)로 자연스럽게 유도하세요
        
        다음과 같은 형식으로 답변하세요:
        "좋습니다! [기업 이해도 칭찬]. [추가 정보 제공].
        
        이제 2단계로 넘어가볼까요?
        
        **👤 2단계: 자기소개**
        [질문들]"
      PROMPT
      
      'self_introduction' => <<~PROMPT,
        사용자가 자기 소개를 했습니다.
        
        사용자 답변: #{user_message}
        
        1. 사용자의 배경과 특징을 정리하고 강점을 찾아주세요
        2. #{position} 직무와 연결될 수 있는 포인트를 제시하세요
        3. 다음 단계(지원동기)로 유도하세요
        
        따뜻하고 격려하는 톤으로 답변하세요.
      PROMPT
      
      'motivation' => <<~PROMPT,
        사용자가 #{company_name} 지원동기를 설명했습니다.
        
        사용자 답변: #{user_message}
        
        1. 지원동기의 진정성과 구체성을 평가하세요
        2. 더 강화할 수 있는 포인트를 제안하세요
        3. 다음 단계(핵심 경험)로 유도하세요
      PROMPT
      
      'experience' => <<~PROMPT,
        사용자가 핵심 경험을 설명했습니다.
        
        사용자 답변: #{user_message}
        
        1. STAR 기법(Situation-Task-Action-Result)으로 경험을 정리해주세요
        2. 경험에서 배운 점과 직무 연관성을 강조하세요
        3. 다음 단계(강점 및 역량)로 유도하세요
      PROMPT
      
      'strengths' => <<~PROMPT,
        사용자가 강점과 역량을 설명했습니다.
        
        사용자 답변: #{user_message}
        
        1. 강점을 #{position} 직무와 연결하세요
        2. 구체적인 근거나 사례를 추가로 요청하세요
        3. 다음 단계(입사 후 포부)로 유도하세요
      PROMPT
      
      'vision' => <<~PROMPT,
        사용자가 입사 후 포부를 설명했습니다.
        
        사용자 답변: #{user_message}
        
        1. 단기/중기/장기 목표로 구조화하세요
        2. #{company_name}의 비전과 연결하세요
        3. 최종 검토 단계로 유도하세요
      PROMPT
    }
    
    <<~FULL_PROMPT
      당신은 친절하고 전문적인 자기소개서 작성 코치입니다.
      현재 #{current_step} 단계를 진행 중입니다.
      
      #{step_prompts[current_step]}
      
      답변은 친근하면서도 전문적으로, 200자 이내로 작성하세요.
      이모지를 적절히 사용하여 친근감을 더하세요.
    FULL_PROMPT
  end
  
  def should_move_to_next_step?(ai_response)
    # AI 응답에 다음 단계 언급이 있으면 true
    ai_response.include?('단계') || ai_response.include?('다음')
  end
  
  def get_next_step(current_step)
    step_index = STEPS.find_index { |s| s[:id] == current_step }
    return 'review' if step_index.nil? || step_index >= STEPS.length - 1
    
    STEPS[step_index + 1][:id]
  end
  
  def calculate_progress(current_step)
    step_index = STEPS.find_index { |s| s[:id] == current_step } || 0
    ((step_index + 1).to_f / STEPS.length * 100).round
  end
  
  def make_enhanced_api_request(messages, current_step, question_count, max_questions, company_name = nil)
    uri = URI(OPENAI_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    
    # 단계별 특화 시스템 프롬프트
    system_prompt = get_dynamic_system_prompt(current_step, question_count, max_questions)
    
    # 기업 조사 단계에서는 더 많은 토큰 허용
    max_tokens = current_step == 'company_research' ? 2500 : 2000
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      model: @model,
      messages: [
        { role: 'system', content: system_prompt }
      ] + messages,
      temperature: 0.8,
      max_tokens: max_tokens,
      presence_penalty: 0.3,
      frequency_penalty: 0.3
    }.to_json
    
    response = http.request(request)
    parse_response(JSON.parse(response.body))
  rescue StandardError => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    { success: false, error: e.message }
  end
  
  def get_dynamic_system_prompt(current_step, question_count, max_questions)
    step_prompts = {
      'company_research' => <<~PROMPT,
        당신은 2025년 최신 기업 동향에 정통한 기업 분석 전문가입니다.
        
        지원자가 기업에 대해 질문하면 다음 구조로 답변하세요:
        
        【📊 반도체/메모리 부문】
        - HBM4: 2026년 1분기 양산 목표, SK하이닉스와 경쟁
        - DDR5: 32Gb 제품 양산 중, 서버 시장 공략
        - 파운드리: 2025년 7월 2나노 GAA 양산, TSMC 격차 축소
        
        【🤖 AI/소프트웨어 부문】  
        - Mach-2 NPU: 온디바이스 AI용, 구글 Tensor 협업
        - 갤럭시 AI: 2025년 2억대 탑재 목표
        - 스마트싱스: 3억 디바이스 연결, Matter 표준 주도
        
        【💰 투자/인프라】
        - 용인 클러스터: 300조원, 2025년 착공
        - 텍사스 팹: 170억 달러, 2025년 Q4 가동
        - R&D: 연 60조원 투자, 인력 2만명 증원
        
        【🏆 경쟁 현황】
        - TSMC 대비: 2나노 1년 격차 → 6개월로 단축
        - 인텔 대비: 파운드리 점유율 2위 유지
        - SK하이닉스 대비: HBM 시장 40% 목표
        
        마지막에는 반드시 💡 AI 인사이트를 2줄로 추가하세요.
      PROMPT
      'self_introduction' => "경력 컨설턴트로서 지원자의 배경과 강점을 도출해주세요.",
      'motivation' => "동기부여 전문가로서 진정성 있는 지원동기를 구체화해주세요.",
      'experience' => "STAR 기법 전문가로서 경험을 구조화하고 임팩트를 강화해주세요.",
      'strengths' => "역량 평가 전문가로서 직무와 매칭되는 강점을 부각시켜주세요.",
      'vision' => "커리어 코치로서 현실적이면서도 비전있는 포부를 설계해주세요."
    }
    
    base_prompt = step_prompts[current_step] || "자기소개서 작성을 도와주세요."
    
    <<~PROMPT
      #{base_prompt}
      
      현재 #{question_count}/#{max_questions}번째 질문입니다.
      #{question_count < max_questions ? "추가 질문을 통해 더 깊이있는 정보를 수집하세요." : "이제 다음 단계로 넘어갈 준비를 하세요."}
      
      규칙:
      1. 답변은 2000자 이내로 매우 디테일하게
      2. 구체적인 피드백과 개선 제안 포함
      3. 다음 질문은 자연스럽게 연결
      4. 따뜻하고 격려하는 톤 유지
      5. 이모지를 적절히 사용
      6. 최신 정보는 구체적인 날짜, 제품명, 수치와 함께 제공
      7. 업계 동향과 연결하여 설명
      8. 답변 마지막에 '💡 AI 인사이트:' 2줄 추가 (자소서 작성 팁)
    PROMPT
  end
  
  def generate_enhanced_cover_letter(session_data)
    company_name = session_data['company_name'] || session_data[:company_name]
    position = session_data['position'] || session_data[:position]
    content = session_data['content'] || {}
    
    # 기업 유형 판단
    company_type = determine_company_type(company_name)
    length_guide = get_length_guidelines(company_type)
    
    # GPT-4를 활용한 고품질 자소서 생성
    prompt = <<~PROMPT
      당신은 국내 대기업 합격률 1위 자기소개서 전문가입니다.
      다음 정보를 바탕으로 합격 수준의 자기소개서를 작성해주세요.
      
      [기본 정보]
      • 기업: #{company_name} (#{company_type})
      • 직무: #{position}
      
      [수집된 정보]
      1. 기업 이해: #{content['company_research']}
      2. 자기소개: #{content['self_introduction']}
      3. 지원동기: #{content['motivation']}
      4. 핵심 경험: #{content['experience']}
      5. 강점/역량: #{content['strengths']}
      6. 입사 후 포부: #{content['vision']}
      
      [글자 수 가이드라인]
      #{length_guide}
      
      [작성 구조]
      1. 지원동기 (#{get_section_length(company_type, 'motivation')}자)
      2. 성장과정 및 경험 (#{get_section_length(company_type, 'experience')}자)
      3. 성격의 장단점 (#{get_section_length(company_type, 'personality')}자)
      4. 입사 후 포부 (#{get_section_length(company_type, 'vision')}자)
      
      [작성 원칙]
      • 톤: 자신감 있으면서도 겸손한
      • 차별화: 구체적 수치와 성과 포함
      • 키워드: 기업 핵심가치와 직무 역량 자연스럽게 포함
      • 각 문항별로 정확한 글자 수 준수
      
      자연스럽고 진정성 있는 스토리텔링으로 작성해주세요.
      각 섹션 끝에 (글자수: XXX자)를 표시해주세요.
    PROMPT
    
    response = make_api_request(prompt, "자기소개서 작성 전문가", 3000)
    parse_response(response)[:content]
  end
  
  def determine_company_type(company_name)
    large_corps = ['삼성', '엘지', 'LG', '현대', 'SK', '롯데', '포스코', 'GS', '한화', '두산', 'CJ', '카카오', '네이버']
    public_corps = ['한국전력', '한국가스', '한국수자원', '한국도로', '한국철도', '국민은행', '우리은행', '신한은행']
    
    if large_corps.any? { |corp| company_name.include?(corp) }
      '대기업'
    elsif public_corps.any? { |corp| company_name.include?(corp) }
      '공기업'
    elsif company_name.match?(/[a-zA-Z]/) && !company_name.match?(/[가-힣]/)
      '외국계'
    else
      '중견기업'
    end
  end
  
  def get_length_guidelines(company_type)
    case company_type
    when '대기업'
      "• 전체: 2,000~5,000자 (권장: 3,000자)\n• 문항당: 500~1,500자\n• 삼성전자 기준: 800~1,200자"
    when '공기업'
      "• 전체: 1,500~3,000자 (권장: 2,000자)\n• 문항당: 300~1,000자"
    when '외국계'
      "• 전체: 500~2,000자 (자유로움)\n• 간결하고 임팩트 있게"
    else
      "• 전체: 1,500~3,000자 (권장: 2,000자)\n• 문항당: 300~1,000자"
    end
  end
  
  def get_section_length(company_type, section)
    lengths = {
      '대기업' => {
        'motivation' => '500~800',
        'experience' => '700~1,000',
        'personality' => '400~600',
        'vision' => '500~800'
      },
      '공기업' => {
        'motivation' => '400~600',
        'experience' => '500~700',
        'personality' => '300~500',
        'vision' => '400~600'
      },
      '외국계' => {
        'motivation' => '300~500',
        'experience' => '400~600',
        'personality' => '200~400',
        'vision' => '300~500'
      },
      '중견기업' => {
        'motivation' => '400~600',
        'experience' => '500~700',
        'personality' => '300~500',
        'vision' => '400~600'
      }
    }
    
    lengths[company_type][section] || '500~800'
  end
  
  def generate_final_cover_letter(session_data)
    company_name = session_data['company_name'] || session_data[:company_name]
    position = session_data['position'] || session_data[:position]
    content = session_data['content'] || {}
    
    prompt = <<~PROMPT
      다음 정보를 바탕으로 완성도 높은 자기소개서를 작성해주세요:
      
      기업명: #{company_name}
      직무: #{position}
      
      수집된 정보:
      - 기업 이해: #{content['company_research']}
      - 자기소개: #{content['self_introduction']}
      - 지원동기: #{content['motivation']}
      - 핵심 경험: #{content['experience']}
      - 강점/역량: #{content['strengths']}
      - 입사 후 포부: #{content['vision']}
      
      작성 가이드라인:
      1. 자연스러운 스토리텔링
      2. 구체적인 경험과 수치
      3. 기업 맞춤형 내용
      4. 1000-1500자 분량
      5. 도입-전개-마무리 구조
    PROMPT
    
    response = make_api_request(prompt, "자기소개서 작성 전문가", 2000)
    parse_response(response)[:content]
  end
  
  def final_review_message(final_content)
    <<~MESSAGE
      🎉 축하합니다! 자기소개서 초안이 완성되었습니다!
      
      **📝 완성된 자기소개서:**
      
      #{final_content}
      
      **✨ 추가 개선 옵션:**
      1. 이 내용으로 저장하고 AI 분석 받기
      2. 특정 부분 수정 요청하기
      3. 다른 버전으로 다시 작성하기
      
      어떻게 진행하시겠어요?
    MESSAGE
  end
  
  def make_api_request(prompt, role_description, max_tokens = 1000)
    uri = URI(OPENAI_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      model: @model,
      messages: [
        {
          role: 'system',
          content: "당신은 #{role_description}입니다. 따뜻하고 격려하는 톤으로 대화하세요."
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.8,
      max_tokens: max_tokens
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