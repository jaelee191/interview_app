require 'net/http'
require 'json'

class AdvancedCoverLetterService
  OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions'
  
  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    @model = ENV['OPENAI_MODEL'] || 'gpt-4.1'
  end
  
  def analyze_complete(content, company_name, position)
    return { error: "API 키가 설정되지 않았습니다" } unless @api_key
    
    # 1단계: 기업 분석
    company_analysis = analyze_company(company_name)
    
    # 2단계: 자기소개서 분석
    cover_letter_analysis = analyze_cover_letter(content)
    
    # 3단계: 맞춤형 자기소개서 생성
    customized_letter = generate_customized_letter(
      company_name, 
      position,
      company_analysis,
      cover_letter_analysis,
      content
    )
    
    {
      success: true,
      company_analysis: company_analysis,
      cover_letter_analysis: cover_letter_analysis,
      customized_letter: customized_letter,
      full_analysis: format_full_analysis(company_analysis, cover_letter_analysis, customized_letter)
    }
  rescue StandardError => e
    Rails.logger.error "고급 분석 오류: #{e.message}"
    { error: "분석 중 오류가 발생했습니다: #{e.message}" }
  end
  
  private
  
  def analyze_company(company_name)
    prompt = <<~PROMPT
      당신은 기업 분석 전문가입니다. #{company_name}에 대해 다음을 분석해주세요:

      **분석 항목:**
      1. 기업의 핵심 사업 분야와 비전
      2. 최근 1년간 주요 이슈 및 현안 (경영진 발언, 신사업, 위기상황 등)
      3. 업계 내 포지션과 경쟁우위
      4. 기업이 추구하는 인재상과 핵심 역량
      5. 조직문화와 가치관

      **출력 형식:**
      ## 🏢 #{company_name} 분석 리포트
      **핵심 사업:** [간단 설명]
      **최근 현안:** [3-5개 주요 이슈]
      **인재상:** [원하는 인재 유형]
      **키워드:** [핵심 키워드 5개]
      
      한국 기업의 최신 정보를 바탕으로 구체적으로 분석해주세요.
    PROMPT
    
    response = make_api_request(prompt, "기업 분석 전문가")
    parse_response(response)[:content]
  end
  
  def analyze_cover_letter(content)
    prompt = <<~PROMPT
      당신은 국내 대기업 인사팀에서 15년간 수만 건의 자기소개서를 평가해온 선배입니다.
      후배에게 진심 어린 조언을 해주듯이, 따뜻하면서도 솔직한 피드백을 제공해주세요.
      
      ## 📝 자기소개서 심층 분석
      
      안녕하세요, 자기소개서를 꼼꼼히 읽어보았습니다.
      
      ### 🎯 첫인상과 전체적인 느낌
      [자기소개서를 처음 읽었을 때의 솔직한 인상을 3-4문장으로 풍부하게 서술]
      "안녕하세요! 자기소개서를 처음 읽었을 때 ~한 느낌을 받았습니다. 
      특히 ~부분에서 ~한 점이 매우 인상적이었고, ~한 역량이 돋보였습니다.
      전반적으로 ~한 지원자로 보이며, ~한 잠재력이 느껴집니다.
      다만 ~한 부분은 조금 더 보완하면 훨씬 좋을 것 같네요."
      
      ### 💪 잘 쓴 부분 (이건 정말 좋아요!)
      [구체적으로 어떤 부분이 왜 좋은지 선배의 관점에서 상세하게 설명]
      
      1. **[구체적인 강점 제목]**
         "~부분에서 ~하게 표현한 것이 정말 좋았습니다. 특히 '~'라는 표현은 정말 인상적이었어요.
         실제로 인사팀에서는 이런 부분을 높게 평가하는데, 왜냐하면 ~하기 때문입니다. 
         제가 본 합격자들 중 상위 10%가 이런 식으로 작성했습니다. 
         많은 지원자들이 놓치는 부분인데 정확히 짚어주셨네요."
      
      2. **[두 번째 강점 제목]**
         "~경험을 ~하게 풀어낸 것도 탁월했습니다. 
         단순히 '~했다'가 아니라 '~를 통해 ~를 달성했고, 그 과정에서 ~를 배웠다'는 식으로
         과정-결과-학습을 모두 담아낸 점이 프로페셔널합니다.
         이런 서술 방식은 지원자의 사고 프로세스를 잘 보여주기 때문에 면접관들이 좋아합니다."
      
      3. **[세 번째 강점 제목]**
         "또한 ~한 부분도 눈여겨봤습니다. 보통 신입 지원자들은 ~하게 쓰는 경향이 있는데,
         당신은 ~하게 접근했더군요. 이건 경력자들도 쉽게 하지 못하는 부분입니다.
         특히 '~' 부분은 정말 차별화된 관점이었어요."
      
      ### 😟 아쉬운 부분 (이건 꼭 보완하세요)
      [개선이 필요한 부분을 부드럽지만 명확하게, 그리고 상세하게 지적]
      
      1. **[구체적인 개선점 제목]**
         "~부분이 조금 아쉬웠습니다. 지금 '~'라고 쓰셨는데, 이 표현이 너무 추상적이에요.
         예를 들어 '~를 개발하겠다'보다는 '~기술을 활용하여 ~를 ~% 개선하는 ~시스템을 구축하겠다'처럼
         구체적인 방법론과 예상 성과까지 제시하면 훨씬 설득력이 있을 거예요.
         
         제가 본 합격자들은 대부분 이런 식으로 작성했습니다:
         '현재 ~의 문제점을 파악하고, ~기술을 적용하여 3개월 내 ~를 달성하겠습니다.'
         
         이렇게 쓰면 면접관이 '아, 이 사람은 정말 구체적인 계획이 있구나'라고 느낍니다."
      
      2. **[두 번째 개선점 제목]**
         "~경험을 설명하신 부분도 보완이 필요합니다. 
         '~를 했습니다'로 끝나는데, 여기서 더 나아가야 해요.
         
         인사담당자들이 정말 궁금해하는 건 이런 것들입니다:
         • 왜 그 방법을 선택했나요?
         • 어떤 어려움이 있었고, 어떻게 극복했나요?
         • 그 경험에서 무엇을 배웠고, 우리 회사에서 어떻게 활용할 건가요?
         
         예를 들어 이렇게 수정해보세요:
         '~프로젝트에서 ~문제에 직면했을 때, A안과 B안을 비교 검토한 결과 ~때문에 B를 선택했고,
         ~라는 예상치 못한 이슈를 ~방법으로 해결하여 최종적으로 ~성과를 달성했습니다.
         이 경험을 통해 ~를 배웠고, 귀사에서 ~업무 시 이를 활용하여 ~하겠습니다.'"
      
      3. **[세 번째 개선점 제목]**
         "마지막으로 ~부분인데요, 이 부분은 정말 중요한데 너무 간략하게 지나가셨어요.
         지금은 '~하겠습니다'로만 되어 있는데, HOW가 빠져있습니다.
         
         이 부분을 이렇게 확장해보세요:
         • 단기(입사 후 3개월): ~를 파악하고 ~를 습득하여 ~
         • 중기(1년): ~프로젝트를 주도하여 ~성과 창출
         • 장기(3년): ~분야의 전문가로 성장하여 ~에 기여
         
         이렇게 구체적인 로드맵을 제시하면 '준비된 인재'라는 인상을 줄 수 있습니다."
      
      ### 🔍 놓치고 있는 숨은 보석들
      "자기소개서를 읽으면서 '아, 이 경험도 있는데 왜 안 썼을까?' 싶은 부분들이 있었습니다.
      
      • **[잠재 경험 1]**: ~하신 경험이 있다면, 이건 꼭 넣으셔야 해요. 왜냐하면 ~
      • **[잠재 경험 2]**: ~능력을 보여줄 수 있는 에피소드가 있다면 ~부분에 추가하면 좋겠습니다.
      • **[잠재 경험 3]**: 혹시 ~해본 적 있으신가요? 있다면 이건 정말 차별화 포인트가 될 수 있습니다.
      
      ### 💡 인사담당자의 시선으로 본 예상 질문
      "만약 제가 면접관이라면 이런 질문을 하고 싶을 것 같아요:
      
      1. "[예상 질문 1]" 
         → 이 질문이 나올 수 있으니 ~에 대해 준비하시면 좋겠습니다.
      
      2. "[예상 질문 2]"
         → 자소서에서 ~부분이 애매해서 나올 가능성이 높습니다.
      
      3. "[예상 질문 3]"
         → ~경험에 대해 더 구체적으로 물어볼 것 같네요.
      
      ### 📊 현실적인 평가 (100점 만점)
      
      **현재 점수: [점수]/100점**
      
      솔직히 말씀드리면, 현재 상태로는 **[상위 몇%]** 정도 수준입니다.
      [점수에 대한 따뜻하지만 현실적인 설명]
      
      • 구조와 논리성: [점수]/20 - [한 줄 평가]
      • 구체성과 신뢰성: [점수]/20 - [한 줄 평가]  
      • 차별화: [점수]/20 - [한 줄 평가]
      • 직무 적합성: [점수]/20 - [한 줄 평가]
      • 문장력: [점수]/20 - [한 줄 평가]
      
      
      ### 💬 마지막으로...
      
      [격려와 응원의 메시지를 2-3문장으로]
      예시: "전반적으로 ~한 잠재력이 보이는 자기소개서입니다. 특히 ~한 부분은 정말 좋았어요. 
      위에서 말씀드린 부분들만 보완하신다면 충분히 경쟁력 있는 자기소개서가 될 것 같습니다. 화이팅!"
      
      ---
      💼 15년차 인사팀 선배가 드리는 진심 어린 조언
      
      자기소개서 내용:
      #{content}
    PROMPT
    
    response = make_api_request(prompt, "대기업 인사팀 15년 경력 선배", 4000)
    parse_response(response)[:content]
  end
  
  def generate_customized_letter(company_name, position, company_analysis, cl_analysis, original_content)
    prompt = <<~PROMPT
      당신은 전문 자기소개서 작성 컨설턴트입니다. 

      **주어진 정보:**
      - 목표 기업: #{company_name}
      - 지원 직무: #{position}
      - 기업 분석 결과: 
      #{company_analysis}
      
      - 지원자 분석 결과: 
      #{cl_analysis}
      
      - 기존 자기소개서: 
      #{original_content}

      **작성 가이드라인:**
      1. 기업의 현안과 지원자 경험을 자연스럽게 연결
      2. 기업이 원하는 인재상에 맞춰 강점 부각
      3. 구체적 수치와 성과로 신뢰성 확보
      4. 기업 키워드를 자연스럽게 포함
      5. 차별화된 인사이트와 관점 제시

      **출력 형식:**
      ## ✨ #{company_name} 맞춤 자기소개서

      ### 지원동기 및 포부
      [기업 현안과 연결된 개인 경험을 바탕으로 한 답변]
      - 기업 이슈 반영: [어떤 현안을 어떻게 반영했는지]
      - 차별화 포인트: [다른 지원자와 구별되는 관점]

      ### 직무 역량 및 경험
      [직무와 관련된 구체적 경험과 성과]
      - 핵심 역량 강조: [기업이 원하는 역량과 매칭]
      - 성과 수치화: [구체적 숫자와 임팩트]

      ### 입사 후 포부
      [기업의 미래 방향성과 연계한 비전]
      - 기여 방안: [구체적인 기여 계획]
      - 성장 비전: [장기적 목표]

      **💡 작성 인사이트:**
      - 활용된 기업 현안: [리스트]
      - 강조된 개인 역량: [리스트]  
      - 차별화 전략: [설명]
    PROMPT
    
    response = make_api_request(prompt, "자기소개서 작성 컨설턴트", 6000)
    parse_response(response)[:content]
  end
  
  def format_full_analysis(company_analysis, cl_analysis, customized_letter)
    <<~ANALYSIS
      ═══════════════════════════════════════════════════════════
      🎯 AI 자기소개서 3단계 심층 분석 완료
      ═══════════════════════════════════════════════════════════
      
      #{company_analysis}
      
      ───────────────────────────────────────────────────────────
      
      #{cl_analysis}
      
      ───────────────────────────────────────────────────────────
      
      #{customized_letter}
      
      ═══════════════════════════════════════════════════════════
      💼 분석 완료 | Powered by GPT-4o
      ═══════════════════════════════════════════════════════════
    ANALYSIS
  end
  
  def make_api_request(prompt, role_description, max_tokens = 3000)
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
          content: "당신은 #{role_description}입니다. 한국 기업과 채용 시장에 대한 깊은 이해를 바탕으로 전문적이고 실용적인 조언을 제공합니다."
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.7,
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