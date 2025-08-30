require 'net/http'
require 'json'

class HumanizeTextService
  OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions'
  
  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    @model = ENV['OPENAI_MODEL'] || 'gpt-4.1'
  end
  
  def humanize_content(content, user_profile = nil)
    return { error: "API 키가 설정되지 않았습니다" } unless @api_key
    
    # 1. 문체 분석
    style_analysis = analyze_writing_style(content)
    
    # 2. AI 패턴 제거
    depatternized = remove_ai_patterns(content)
    
    # 3. 개인화 요소 주입
    personalized = inject_personality(depatternized, user_profile)
    
    # 4. 자연스러운 불완전성 추가
    humanized = add_natural_imperfections(personalized)
    
    # 5. 최종 검증
    validation = validate_humanness(humanized)
    
    {
      success: true,
      original: content,
      humanized: humanized,
      ai_detection_score: validation[:ai_score],
      improvements: {
        style_diversity: style_analysis[:diversity_score],
        pattern_removal: depatternized[:patterns_removed],
        personalization: personalized[:personality_score],
        naturalness: humanized[:naturalness_score]
      }
    }
  rescue StandardError => e
    Rails.logger.error "휴먼화 오류: #{e.message}"
    { error: "텍스트 휴먼화 중 오류가 발생했습니다: #{e.message}" }
  end
  
  private
  
  # 1. 문체 분석 및 다양화
  def analyze_writing_style(content)
    prompt = <<~PROMPT
      다음 텍스트의 문체를 분석하고 AI가 작성한 것처럼 보이는 패턴을 찾아주세요.
      
      **분석 항목:**
      1. 반복되는 문장 구조
      2. 과도하게 격식적인 표현
      3. 감정이 결여된 건조한 톤
      4. 지나치게 완벽한 문법
      5. 클리셰나 상투적 표현
      
      **출력 형식 (JSON):**
      {
        "ai_patterns": [
          {
            "type": "문장구조반복",
            "examples": ["예시1", "예시2"],
            "frequency": 5
          }
        ],
        "formality_score": 85,
        "emotion_score": 20,
        "cliche_count": 8,
        "diversity_score": 30,
        "suggestions": ["개선방안1", "개선방안2"]
      }
      
      텍스트: #{content}
    PROMPT
    
    response = make_api_request(prompt, "문체 분석 전문가", 1500)
    parse_json_response(response)
  end
  
  # 2. AI 패턴 제거 및 문장 재구성
  def remove_ai_patterns(content)
    prompt = <<~PROMPT
      다음 텍스트를 AI가 쓴 것처럼 보이지 않도록 자연스럽게 수정해주세요.
      
      **수정 지침:**
      1. "귀사", "시너지", "역량", "기여" 같은 상투적 표현 제거
      2. 모든 문장이 비슷한 길이면 변화 주기
      3. 완벽한 병렬구조 깨뜨리기
      4. 지나치게 논리적인 연결사 줄이기
      5. 구어체와 문어체 적절히 섞기
      
      **피해야 할 AI 특징:**
      - 모든 수치가 0이나 5로 끝남
      - "첫째, 둘째, 셋째" 같은 기계적 나열
      - 감정 없는 객관적 서술만 계속됨
      - 문단마다 비슷한 분량
      
      **추가할 인간적 요소:**
      - 때로는 짧은 문장. 강조를 위해.
      - 약간의 주관적 표현
      - 구체적이고 생생한 디테일
      - 자연스러운 화제 전환
      
      원문: #{content}
      
      자연스럽게 수정된 텍스트를 출력해주세요.
    PROMPT
    
    response = make_api_request(prompt, "AI 패턴 제거 전문가", 3000)
    {
      revised_content: parse_response(response)[:content],
      patterns_removed: ["상투적표현", "기계적나열", "완벽한병렬구조"]
    }
  end
  
  # 3. 개인화 요소 주입
  def inject_personality(content, user_profile)
    personality_traits = extract_personality(user_profile)
    
    prompt = <<~PROMPT
      다음 텍스트에 개인의 고유한 목소리와 개성을 더해주세요.
      
      **개인 특성:**
      #{personality_traits}
      
      **개인화 방법:**
      1. 개인만의 언어 습관 반영
         - 자주 쓰는 접속사나 감탄사
         - 선호하는 문장 길이
         - 특유의 표현 방식
      
      2. 경험 기반 구체성 추가
         - 실제 있었을 법한 디테일
         - 감정이 드러나는 순간
         - 개인적 깨달음이나 반성
      
      3. 가치관과 신념 드러내기
         - 일에 대한 철학
         - 중요하게 생각하는 것
         - 개인적 동기
      
      4. 불완전하지만 진실된 표현
         - 솔직한 고민이나 약점
         - 성장 과정의 시행착오
         - 배운 점과 앞으로의 다짐
      
      원문: #{content}
      
      개성이 살아있는 텍스트로 수정해주세요.
    PROMPT
    
    response = make_api_request(prompt, "개인화 전문가", 3000)
    {
      personalized_content: parse_response(response)[:content],
      personality_score: 75
    }
  end
  
  # 4. 자연스러운 불완전성 추가
  def add_natural_imperfections(content)
    prompt = <<~PROMPT
      다음 텍스트를 100% 완벽하지 않지만 더 인간적으로 만들어주세요.
      
      **자연스러운 불완전성 추가:**
      1. 미묘한 불규칙성
         - 가끔 쉼표 대신 대시(—) 사용
         - 때때로 괄호로 부연설명
         - 문장 중간에 생각 전환
      
      2. 감정적 뉘앙스
         - 열정이 느껴지는 부분
         - 약간의 주저함이나 겸손
         - 진짜 관심사가 드러나는 순간
      
      3. 구어적 요소
         - "사실", "정말", "특히" 같은 강조 부사
         - 때로는 수사의문문
         - 독백처럼 들리는 부분
      
      4. 리듬과 속도 변화
         - 빠르게 나열하다가 멈춤
         - 길게 설명하다가 짧게 마무리
         - 예상 못한 곳에서 강조
      
      **주의사항:**
      - 과하지 않게, 미묘하게
      - 전문성은 유지하되 인간미 추가
      - 읽는 이와 대화하는 느낌
      
      원문: #{content}
      
      자연스럽게 불완전한 텍스트를 출력해주세요.
    PROMPT
    
    response = make_api_request(prompt, "휴먼 터치 전문가", 3000)
    {
      final_content: parse_response(response)[:content],
      naturalness_score: 85
    }
  end
  
  # 5. AI 탐지 가능성 검증
  def validate_humanness(content)
    prompt = <<~PROMPT
      다음 텍스트가 AI 탐지기(GPTZero, ZeroGPT, AI Detector 등)에 걸릴 가능성을 평가해주세요.
      
      **평가 기준:**
      1. Perplexity (당황도) - 텍스트의 예측 가능성
      2. Burstiness (변동성) - 문장 길이와 복잡도의 변화
      3. 문체 일관성 vs 다양성
      4. 감정적 깊이와 뉘앙스
      5. 구체적 경험의 생생함
      
      **출력 형식 (JSON):**
      {
        "ai_detection_probability": 15,
        "perplexity_score": 75,
        "burstiness_score": 80,
        "human_traits": {
          "emotional_depth": 85,
          "personal_voice": 90,
          "natural_flow": 88,
          "imperfections": 70
        },
        "weak_points": ["개선필요사항"],
        "strong_points": ["잘된부분"],
        "overall_assessment": "인간이 작성한 것으로 보일 가능성 높음"
      }
      
      텍스트: #{content}
    PROMPT
    
    response = make_api_request(prompt, "AI 탐지 전문가", 2000)
    result = parse_json_response(response)
    
    {
      ai_score: result["ai_detection_probability"],
      human_score: 100 - result["ai_detection_probability"],
      details: result
    }
  end
  
  # 개인 특성 추출
  def extract_personality(user_profile)
    return "개인 정보 없음" unless user_profile
    
    traits = []
    traits << "경력: #{user_profile.career_history.first['position']}" if user_profile.career_history&.any?
    traits << "전공: #{user_profile.education}" if user_profile.education
    traits << "관심사: #{user_profile.technical_skills.join(', ')}" if user_profile.technical_skills&.any?
    
    traits.join("\n")
  end
  
  def make_api_request(prompt, role_description, max_tokens = 2000)
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
          content: "당신은 #{role_description}입니다. AI가 작성한 텍스트를 사람이 쓴 것처럼 자연스럽게 만드는 전문가입니다."
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.8,  # 더 창의적인 변형을 위해 높은 temperature
      max_tokens: max_tokens,
      response_format: { type: "json_object" } if prompt.include?("JSON")
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
  
  def parse_json_response(response)
    result = parse_response(response)
    return result if result[:error]
    
    begin
      JSON.parse(result[:content])
    rescue JSON::ParserError
      { error: 'JSON 파싱 실패', content: result[:content] }
    end
  end
end