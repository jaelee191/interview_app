require 'net/http'
require 'json'

class OpenaiService
  OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions'
  
  def initialize
    @api_key = ENV['OPENAI_API_KEY'] || Rails.application.credentials.openai[:api_key] rescue nil
    @model = ENV['OPENAI_MODEL'] || 'gpt-4.1'
  end
  
  def analyze_cover_letter(content, company_name = nil, position = nil)
    return { error: "API 키가 설정되지 않았습니다" } unless @api_key
    
    prompt = build_analysis_prompt(content, company_name, position)
    
    response = make_api_request(prompt)
    parse_response(response)
  rescue StandardError => e
    Rails.logger.error "OpenAI API 오류: #{e.message}"
    { error: "분석 중 오류가 발생했습니다: #{e.message}" }
  end
  
  private
  
  def build_analysis_prompt(content, company_name, position)
    context = "다음 자기소개서를 분석해주세요."
    context += " 지원 기업: #{company_name}" if company_name.present?
    context += " 지원 직무: #{position}" if position.present?
    
    <<~PROMPT
      #{context}
      
      자기소개서 내용:
      #{content}
      
      다음 항목들을 평가하고 개선점을 제시해주세요:
      
      1. **전체 평점** (100점 만점)
      
      2. **강점 분석** (3-5개)
      
      3. **개선이 필요한 부분** (3-5개)
      
      4. **구조 및 논리성** (10점 만점)
         - 도입부, 본론, 결론의 구성
         - 문단 간 연결성
      
      5. **구체성 및 신뢰성** (10점 만점)
         - 구체적인 경험과 성과 제시
         - 수치화된 성과 포함 여부
      
      6. **직무 적합성** (10점 만점)
         - 지원 직무와의 연관성
         - 필요 역량 강조 여부
      
      7. **차별화 포인트** (10점 만점)
         - 독창성과 개성
         - 경쟁력 있는 강점 부각
      
      8. **문장력 및 표현** (10점 만점)
         - 문법 및 맞춤법
         - 간결하고 명확한 표현
      
      9. **개선 제안사항**
         - 구체적인 수정 방향 3-5개
      
      10. **추천 키워드**
          - 추가하면 좋을 키워드 5-10개
      
      한국어로 상세하고 건설적인 피드백을 제공해주세요.
    PROMPT
  end
  
  def make_api_request(prompt)
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
          content: '당신은 전문 HR 컨설턴트이자 자기소개서 첨삭 전문가입니다. 건설적이고 실용적인 피드백을 제공해주세요.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.7,
      max_tokens: 4000
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
        analysis: response['choices'].first['message']['content'],
        usage: response['usage']
      }
    else
      { error: '예상치 못한 응답 형식입니다' }
    end
  end
end