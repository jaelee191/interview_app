# MCP Playwright를 활용한 채용공고 스냅샷 분석 서비스
# 사람인 등 복사 방지가 적용된 사이트의 채용공고를 스냅샷으로 분석

class McpJobAnalyzerService
  require 'net/http'
  require 'uri'
  require 'json'
  require 'base64'
  
  def initialize
    @openai_service = OpenaiService.new
  end
  
  # 메인 분석 메서드
  def analyze_with_snapshot(url)
    Rails.logger.info "🎯 MCP 기반 채용공고 분석 시작: #{url}"
    
    begin
      # 1단계: MCP Playwright로 페이지 스냅샷 캡처
      screenshot_data = capture_page_screenshot(url)
      
      if screenshot_data[:success]
        Rails.logger.info "📸 스냅샷 캡처 성공"
        
        # 2단계: 스냅샷을 AI로 분석 (GPT-4 Vision)
        analysis_result = analyze_screenshot_with_ai(
          screenshot_data[:screenshot_base64],
          url
        )
        
        # 3단계: 구조화된 정보 추출
        structured_data = extract_structured_info(analysis_result)
        
        # 4단계: 상세 분석 리포트 생성
        detailed_report = generate_detailed_report(structured_data, url)
        
        {
          success: true,
          data: {
            basic_info: structured_data[:basic_info],
            requirements: structured_data[:requirements],
            benefits: structured_data[:benefits],
            analysis_result: detailed_report,
            screenshot_captured: true,
            analyzed_at: Time.current
          }
        }
      else
        Rails.logger.error "❌ 스냅샷 캡처 실패: #{screenshot_data[:error]}"
        { success: false, error: screenshot_data[:error] }
      end
      
    rescue => e
      Rails.logger.error "MCP 분석 오류: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { success: false, error: e.message }
    end
  end
  
  private
  
  # MCP Playwright를 통한 스크린샷 캡처
  def capture_page_screenshot(url)
    Rails.logger.info "📸 Capturing screenshot with MCP Playwright..."
    
    # 파이썬 스냅샷 분석기 실행
    script_path = Rails.root.join('python_analysis', 'mcp_snapshot_analyzer.py')
    
    # 파이썬 환경 경로
    python_env = Rails.root.join('python_analysis_env', 'bin', 'python')
    
    # 파이썬 스크립트 실행
    require 'open3'
    
    command = if File.exist?(python_env)
      "#{python_env} #{script_path} '#{url}'"
    else
      "python3 #{script_path} '#{url}'"
    end
    
    Rails.logger.info "실행 명령: #{command}"
    
    stdout, stderr, status = Open3.capture3(command)
    
    if status.success?
      begin
        result = JSON.parse(stdout)
        Rails.logger.info "스냅샷 캡처 성공: #{result['screenshot_size']} bytes" if result['success']
      rescue JSON::ParserError => e
        Rails.logger.error "JSON 파싱 실패: #{e.message}"
        Rails.logger.error "stdout: #{stdout}"
        result = nil
      end
    else
      Rails.logger.error "스냅샷 캡처 실패: #{stderr}"
      result = nil
    end
    
    if result && result['screenshot']
      {
        success: true,
        screenshot_base64: result['screenshot'],
        text_content: result['text'],
        url: url
      }
    else
      # 폴백: 기본 스크린샷 방식
      {
        success: false,
        error: "스크린샷 캡처 실패"
      }
    end
  end
  
  # GPT-4 Vision을 활용한 스크린샷 분석
  def analyze_screenshot_with_ai(screenshot_base64, url)
    prompt = <<~PROMPT
      다음 채용공고 스크린샷을 분석하여 정보를 추출해주세요.
      복사 방지가 되어 있어 이미지로만 분석 가능합니다.
      
      추출해야 할 정보:
      1. 회사명
      2. 채용 포지션/직무
      3. 주요 업무 내용
      4. 자격 요건 (필수/우대)
      5. 근무 조건 (위치, 급여, 근무시간 등)
      6. 복지 및 혜택
      7. 전형 절차
      8. 마감일
      
      구조화된 JSON 형식으로 응답해주세요.
    PROMPT
    
    # Vision API 호출 (시뮬레이션)
    response = @openai_service.analyze_image_with_gpt4_vision(
      screenshot_base64,
      prompt
    )
    
    begin
      JSON.parse(response)
    rescue
      # JSON 파싱 실패시 텍스트로 반환
      { raw_analysis: response }
    end
  end
  
  # 구조화된 정보 추출
  def extract_structured_info(analysis_result)
    {
      basic_info: {
        company_name: analysis_result['company_name'] || '미확인',
        position: analysis_result['position'] || '미확인',
        location: analysis_result['location'],
        deadline: analysis_result['deadline']
      },
      requirements: {
        required: analysis_result['required_qualifications'] || [],
        preferred: analysis_result['preferred_qualifications'] || []
      },
      benefits: analysis_result['benefits'] || [],
      job_details: analysis_result['job_details'] || '',
      recruitment_process: analysis_result['recruitment_process'] || []
    }
  end
  
  # 상세 분석 리포트 생성
  def generate_detailed_report(structured_data, url)
    company = structured_data[:basic_info][:company_name]
    position = structured_data[:basic_info][:position]
    
    prompt = <<~PROMPT
      다음 채용공고 정보를 바탕으로 지원자를 위한 상세 분석 리포트를 작성해주세요.
      
      회사: #{company}
      포지션: #{position}
      요구사항: #{structured_data[:requirements].to_json}
      
      포함할 내용:
      1. 회사가 찾는 인재상 분석
      2. 핵심 역량 및 키워드
      3. 자소서 작성 전략
      4. 면접 예상 질문
      5. 준비 사항 체크리스트
      
      실용적이고 구체적인 조언을 제공해주세요.
    PROMPT
    
    @openai_service.generate_response(prompt, max_tokens: 2000)
  end
  
  # 파이썬 스크립트 실행 헬퍼
  def execute_python_script(script)
    require 'open3'
    
    # 임시 파일에 스크립트 저장
    temp_file = Tempfile.new(['mcp_capture', '.py'])
    temp_file.write(script)
    temp_file.close
    
    begin
      # 파이썬 실행
      stdout, stderr, status = Open3.capture3(
        "python3", temp_file.path
      )
      
      if status.success?
        JSON.parse(stdout)
      else
        Rails.logger.error "Python execution failed: #{stderr}"
        nil
      end
    ensure
      temp_file.unlink
    end
  end
end

# OpenAI 서비스 확장 (Vision API 지원)
class OpenaiService
  def analyze_image_with_gpt4_vision(image_base64, prompt)
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    
    response = client.chat(
      parameters: {
        model: "gpt-4-vision-preview",
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: prompt },
              {
                type: "image_url",
                image_url: {
                  url: "data:image/png;base64,#{image_base64}",
                  detail: "high"
                }
              }
            ]
          }
        ],
        max_tokens: 4096
      }
    )
    
    response.dig("choices", 0, "message", "content")
  rescue => e
    Rails.logger.error "GPT-4 Vision API error: #{e.message}"
    "분석 실패: #{e.message}"
  end
end