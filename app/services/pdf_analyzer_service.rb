require 'pdf-reader'

class PdfAnalyzerService
  def initialize(file_path)
    @file_path = file_path
    @api_key = ENV['OPENAI_API_KEY']
  end
  
  def analyze_resume
    # PDF 페이지별 텍스트 추출
    pages_data = extract_text_by_pages
    
    return { error: "PDF 파일에서 텍스트를 추출할 수 없습니다." } if pages_data.nil?
    
    # 이력서와 자소서 부분 자동 구분
    separated_content = separate_resume_and_cover_letter(pages_data)
    
    # 각 섹션별 AI 분석
    resume_analysis = nil
    cover_letter_analysis = nil
    
    if separated_content[:resume][:text].present?
      resume_analysis = analyze_resume_with_ai(separated_content[:resume][:text])
    end
    
    if separated_content[:cover_letter][:text].present?
      cover_letter_analysis = analyze_cover_letter_with_ai(separated_content[:cover_letter][:text])
    end
    
    # 전체 텍스트 (기존 호환성)
    full_text = pages_data.map { |p| p[:text] }.join("\n")
    
    {
      success: true,
      extracted_text: full_text,
      structured_content: separated_content,
      analysis: {
        resume: resume_analysis,
        cover_letter: cover_letter_analysis,
        combined: analyze_with_ai(full_text) # 전체 통합 분석
      },
      sections: parse_resume_sections(full_text),
      metadata: {
        page_count: @page_count,
        word_count: full_text.split.length,
        resume_pages: separated_content[:resume][:pages],
        cover_letter_pages: separated_content[:cover_letter][:pages],
        analyzed_at: Time.current
      }
    }
  rescue => e
    Rails.logger.error "PDF Analysis Error: #{e.message}"
    { error: "PDF 분석 중 오류가 발생했습니다: #{e.message}" }
  end
  
  private
  
  def extract_text_from_pdf
    reader = PDF::Reader.new(@file_path)
    @page_count = reader.page_count
    
    text = ""
    reader.pages.each do |page|
      text += page.text + "\n"
    end
    
    # 텍스트 정리
    text.gsub(/\s+/, ' ').strip
  rescue => e
    Rails.logger.error "PDF Extraction Error: #{e.message}"
    nil
  end
  
  # 페이지별로 텍스트 추출
  def extract_text_by_pages
    reader = PDF::Reader.new(@file_path)
    @page_count = reader.page_count
    
    pages = []
    reader.pages.each_with_index do |page, index|
      page_text = page.text.strip
      pages << {
        page_number: index + 1,
        text: page_text,
        word_count: page_text.split.length
      }
    end
    
    pages
  rescue => e
    Rails.logger.error "PDF Page Extraction Error: #{e.message}"
    nil
  end
  
  # 이력서와 자소서 부분 자동 구분
  def separate_resume_and_cover_letter(pages_data)
    resume_pages = []
    cover_letter_pages = []
    
    # 자소서 시작 패턴 검색
    cover_letter_patterns = [
      /자기소개/i,
      /자소서/i,
      /지원동기/i,
      /입사.*포부/i,
      /성장과정/i,
      /가치관/i,
      /직무역량/i
    ]
    
    # 이력서 특징 패턴
    resume_patterns = [
      /학력사항/i,
      /경력사항/i,
      /자격증/i,
      /education/i,
      /experience/i,
      /certification/i,
      /skills/i
    ]
    
    cover_letter_start_page = nil
    
    # 각 페이지 분석하여 자소서 시작점 찾기
    pages_data.each_with_index do |page, index|
      text = page[:text]
      
      # 자소서 패턴이 많이 나타나면 자소서 시작으로 판단
      cover_letter_score = cover_letter_patterns.count { |pattern| text =~ pattern }
      resume_score = resume_patterns.count { |pattern| text =~ pattern }
      
      if cover_letter_start_page.nil? && cover_letter_score > resume_score && cover_letter_score >= 2
        cover_letter_start_page = index
      end
    end
    
    # 페이지 분류
    if cover_letter_start_page
      resume_pages = pages_data[0...cover_letter_start_page]
      cover_letter_pages = pages_data[cover_letter_start_page..-1]
    else
      # 자동 분류 실패 시 페이지 수로 추정 (예: 4페이지까지 이력서, 5페이지부터 자소서)
      if pages_data.length > 4
        resume_pages = pages_data[0..3]  # 1-4페이지
        cover_letter_pages = pages_data[4..-1]  # 5페이지부터
      else
        resume_pages = pages_data
        cover_letter_pages = []
      end
    end
    
    {
      resume: {
        pages: resume_pages.map { |p| p[:page_number] },
        text: resume_pages.map { |p| p[:text] }.join("\n\n"),
        word_count: resume_pages.sum { |p| p[:word_count] }
      },
      cover_letter: {
        pages: cover_letter_pages.map { |p| p[:page_number] },
        text: cover_letter_pages.map { |p| p[:text] }.join("\n\n"),
        word_count: cover_letter_pages.sum { |p| p[:word_count] }
      }
    }
  end
  
  # 이력서 전용 분석
  def analyze_resume_with_ai(text)
    prompt = <<~PROMPT
      다음은 지원자의 이력서 부분입니다. 경력 및 역량 중심으로 분석해주세요:
      
      #{text[0..4000]}
      
      ## 1. 경력 요약
      - 총 경력 기간
      - 주요 회사/직책
      - 핵심 성과
      
      ## 2. 기술 스택 분석
      - 주력 기술
      - 보유 자격증
      - 기술 수준 평가
      
      ## 3. 프로젝트 경험
      - 주요 프로젝트
      - 담당 역할
      - 성과/기여도
      
      ## 4. 교육 및 학력
      - 최종 학력
      - 전공 적합도
      - 추가 교육사항
      
      ## 5. 종합 평가
      - 강점 TOP 3
      - 시장 경쟁력
      - 추천 포지션
    PROMPT
    
    response = call_openai_api(prompt)
    response[:content] || "이력서 분석 실패"
  end
  
  # 자기소개서 전용 분석
  def analyze_cover_letter_with_ai(text)
    prompt = <<~PROMPT
      다음은 지원자의 자기소개서 부분입니다. 스토리텔링과 지원동기를 중심으로 분석해주세요:
      
      #{text[0..4000]}
      
      ## 1. 스토리텔링 평가
      - 논리적 구성
      - 설득력
      - 진정성
      
      ## 2. 핵심 메시지 분석
      - 지원동기
      - 입사 후 포부
      - 가치관/비전
      
      ## 3. 차별화 포인트
      - 독특한 경험
      - 특별한 강점
      - 기업과의 적합성
      
      ## 4. 표현력 평가
      - 문장 구성
      - 어휘 선택
      - 가독성
      
      ## 5. 개선 제안
      - 보완 필요 항목
      - 추가하면 좋을 내용
      - 표현 개선점
    PROMPT
    
    response = call_openai_api(prompt)
    response[:content] || "자기소개서 분석 실패"
  end
  
  def analyze_with_ai(text)
    prompt = <<~PROMPT
      다음은 지원자의 이력서/자기소개서 PDF 내용입니다. 상세히 분석해주세요:
      
      #{text[0..5000]} # 처음 5000자만 전송
      
      다음 항목들을 분석해주세요:
      
      ## 1. 지원자 프로필 요약
      - 핵심 경력/학력
      - 주요 기술/역량
      - 특징적인 경험
      
      ## 2. 강점 분석
      - 차별화된 강점 3가지
      - 증명 가능한 성과
      - 시장 가치
      
      ## 3. 개선 필요 사항
      - 보완이 필요한 부분
      - 추가하면 좋을 내용
      - 표현 개선 포인트
      
      ## 4. 직무 적합도 평가
      - 어떤 직무에 적합한지
      - 목표 기업 추천
      - 포지셔닝 전략
      
      ## 5. 자기소개서 작성 가이드
      - 강조해야 할 포인트
      - 스토리텔링 전략
      - 구체적 개선 방안
      
      상세하고 실용적인 피드백을 제공해주세요.
    PROMPT
    
    response = call_openai_api(prompt)
    response[:content] || "분석 실패"
  end
  
  def parse_resume_sections(text)
    sections = {}
    
    # 일반적인 이력서 섹션 패턴
    section_patterns = {
      personal_info: /(?:이름|성명|name|연락처|contact|이메일|email|주소|address)/i,
      education: /(?:학력|education|학교|university|대학)/i,
      experience: /(?:경력|experience|근무|work|직무|job|인턴|intern)/i,
      skills: /(?:기술|skill|역량|competency|자격|certification|언어|language)/i,
      projects: /(?:프로젝트|project|포트폴리오|portfolio)/i,
      awards: /(?:수상|award|성과|achievement|표창)/i,
      introduction: /(?:자기소개|자소서|cover letter|소개|introduction)/i
    }
    
    section_patterns.each do |key, pattern|
      if text =~ pattern
        # 해당 섹션 텍스트 추출 (간단한 구현)
        match_index = text.index(pattern)
        if match_index
          section_text = text[match_index..(match_index + 500)]
          sections[key] = section_text.strip
        end
      end
    end
    
    sections
  end
  
  def call_openai_api(prompt)
    require 'net/http'
    require 'json'
    
    uri = URI('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      model: ENV['OPENAI_MODEL'] || 'gpt-4o-mini',
      messages: [
        { 
          role: 'system', 
          content: '당신은 채용 전문가이자 이력서 컨설턴트입니다. 지원자의 이력서를 분석하고 개선점을 제시하세요.' 
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.7,
      max_tokens: 2000
    }.to_json
    
    response = http.request(request)
    result = JSON.parse(response.body)
    
    if result['choices']
      { content: result['choices'][0]['message']['content'] }
    else
      { error: result['error']&.dig('message') || 'API 오류' }
    end
  rescue => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    { error: e.message }
  end
end