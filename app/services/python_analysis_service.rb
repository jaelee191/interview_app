class PythonAnalysisService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :python_env_path, :string, default: -> { 
    if Rails.env.production? && File.exist?("/rails/venv/bin/python")
      "/rails/venv/bin/python"  # Docker 환경
    else
      Rails.root.join("python_analysis_env/bin/python").to_s  # 개발 환경
    end
  }
  attribute :scripts_path, :string, default: Rails.root.join("python_analysis").to_s

  def initialize(attributes = {})
    super
    ensure_python_environment
  end

  # 채용공고 분석
  def analyze_job_posting(job_data)
    Rails.logger.info "=== 파이썬 채용공고 분석 시작 ==="

    begin
      # 데이터 검증
      validated_data = validate_job_data(job_data)

      # 파이썬 스크립트 실행
      json_input = validated_data.to_json
      result = execute_python_script("analyze_job_posting", json_input)

      # 결과 파싱
      parsed_result = JSON.parse(result)

      if parsed_result["error"]
        Rails.logger.error "파이썬 분석 오류: #{parsed_result['error']}"
        return create_error_response(parsed_result["error"])
      end

      Rails.logger.info "파이썬 채용공고 분석 완료"
      create_success_response(parsed_result)

    rescue => e
      Rails.logger.error "파이썬 분석 서비스 오류: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      create_error_response(e.message)
    end
  end

  # 기업 분석
  def analyze_company(company_data)
    Rails.logger.info "=== 파이썬 기업 분석 시작 ==="

    begin
      # 데이터 검증
      validated_data = validate_company_data(company_data)

      # 파이썬 스크립트 실행
      json_input = validated_data.to_json
      result = execute_python_script("analyze_company", json_input)

      # 결과 파싱
      parsed_result = JSON.parse(result)

      if parsed_result["error"]
        Rails.logger.error "파이썬 분석 오류: #{parsed_result['error']}"
        return create_error_response(parsed_result["error"])
      end

      Rails.logger.info "파이썬 기업 분석 완료"
      create_success_response(parsed_result)

    rescue => e
      Rails.logger.error "파이썬 분석 서비스 오류: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      create_error_response(e.message)
    end
  end

  # 리라이트 텍스트 품질 향상 (전체 향상)
  def enhance_rewrite(text, company_name = nil)
    Rails.logger.info "=== 파이썬 리라이트 향상 시작 ==="
    
    begin
      # 줄바꿈 문자를 이스케이프 처리
      clean_text = text.gsub("\n", " ").gsub("\r", " ").gsub("\"", "'")
      
      input_data = {
        text: clean_text,
        company: company_name || ""
      }
      
      # 파이썬 스크립트 실행
      json_input = input_data.to_json
      result = execute_python_script("enhance_rewrite", json_input)
      
      # 결과 파싱
      parsed_result = JSON.parse(result)
      
      if parsed_result["error"]
        Rails.logger.error "파이썬 향상 오류: #{parsed_result['error']}"
        return create_error_response(parsed_result["error"])
      end
      
      Rails.logger.info "파이썬 리라이트 향상 완료"
      create_success_response(parsed_result)
      
    rescue => e
      Rails.logger.error "파이썬 향상 서비스 오류: #{e.message}"
      create_error_response(e.message)
    end
  end
  
  # 텍스트 품질 분석만 수행 (텍스트 변경 없음)
  def analyze_text_quality(text, company_name = nil)
    Rails.logger.info "=== 파이썬 텍스트 품질 분석 ==="
    
    begin
      # 텍스트 정제 (JSON 안전하게, 줄바꿈은 유지)
      safe_text = text.to_s
        .gsub(/\r\n/, "\n")    # Windows 줄바꿈을 Unix로 통일
        .gsub(/ +/, ' ')       # 공백만 정리 (줄바꿈은 유지)
        .gsub('"', "'")        # 큰따옴표를 작은따옴표로
        .strip
      
      input_data = {
        text: safe_text,
        company: company_name || "",
        mode: "analyze_only"
      }
      
      # 파이썬 스크립트 실행
      json_input = input_data.to_json
      result = execute_python_script("analyze_quality", json_input)
      
      # 결과 파싱
      parsed_result = JSON.parse(result)
      
      if parsed_result["error"]
        Rails.logger.error "파이썬 분석 오류: #{parsed_result['error']}"
        return create_error_response(parsed_result["error"])
      end
      
      Rails.logger.info "파이썬 품질 분석 완료"
      create_success_response(parsed_result)
      
    rescue => e
      Rails.logger.error "파이썬 분석 오류: #{e.message}"
      create_error_response(e.message)
    end
  end
  
  # AI 패턴만 제거 (최소한의 변경)
  def remove_ai_patterns_only(text)
    Rails.logger.info "=== AI 패턴 제거 ==="
    
    begin
      # 텍스트 정제 (줄바꿈은 유지!)
      safe_text = text.to_s
        .gsub(/\r\n/, "\n")  # Windows 줄바꿈을 Unix로 통일
        .gsub(/ +/, ' ')     # 공백만 정리 (줄바꿈은 유지)
        .gsub('"', "'")
        .strip
      
      input_data = {
        text: safe_text,
        mode: "remove_ai_only"
      }
      
      # 파이썬 스크립트 실행
      json_input = input_data.to_json
      result = execute_python_script("remove_ai_patterns", json_input)
      
      # 결과 파싱
      parsed_result = JSON.parse(result)
      
      if parsed_result["error"]
        Rails.logger.error "AI 패턴 제거 오류: #{parsed_result['error']}"
        return create_error_response(parsed_result["error"])
      end
      
      Rails.logger.info "AI 패턴 제거 완료"
      create_success_response(parsed_result)
      
    rescue => e
      Rails.logger.error "AI 패턴 제거 오류: #{e.message}"
      create_error_response(e.message)
    end
  end
  
  # 플레이라이트 MCP 데이터와 파이썬 분석 결합
  def analyze_job_posting_with_playwright(url)
    Rails.logger.info "=== 플레이라이트 + 파이썬 통합 분석 시작 ==="

    begin
      # 1단계: 플레이라이트 MCP로 데이터 수집
      playwright_data = collect_job_posting_data_with_playwright(url)

      if playwright_data[:error]
        return create_error_response("데이터 수집 실패: #{playwright_data[:error]}")
      end

      # 2단계: 파이썬으로 분석
      analysis_result = analyze_job_posting(playwright_data[:data])

      # 3단계: 결과 통합
      integrated_result = {
        crawling_info: playwright_data[:metadata],
        analysis_result: analysis_result[:data],
        integration_timestamp: Time.current.iso8601
      }

      Rails.logger.info "통합 분석 완료"
      create_success_response(integrated_result)

    rescue => e
      Rails.logger.error "통합 분석 오류: #{e.message}"
      create_error_response(e.message)
    end
  end

  # 기업 분석을 위한 통합 데이터 수집 및 분석
  def analyze_company_with_comprehensive_data(company_name)
    Rails.logger.info "=== 기업 종합 분석 시작: #{company_name} ==="

    begin
      # 1단계: 다양한 소스에서 데이터 수집
      company_data = {
        name: company_name,
        basic_info: collect_basic_company_info(company_name),
        news_data: collect_company_news(company_name),
        job_postings: collect_company_job_postings(company_name),
        financial_data: collect_financial_data(company_name)
      }

      # 2단계: 파이썬으로 종합 분석
      analysis_result = analyze_company(company_data)

      Rails.logger.info "기업 종합 분석 완료"
      analysis_result

    rescue => e
      Rails.logger.error "기업 종합 분석 오류: #{e.message}"
      create_error_response(e.message)
    end
  end

  private

  def ensure_python_environment
    unless File.exist?(python_env_path)
      Rails.logger.warn "파이썬 가상환경이 존재하지 않습니다: #{python_env_path}"
    end

    unless File.exist?(File.join(scripts_path, "rails_integration.py"))
      Rails.logger.warn "파이썬 통합 스크립트가 존재하지 않습니다: #{scripts_path}"
    end
  end

  def execute_python_script(command, json_input)
    script_path = File.join(scripts_path, "rails_integration.py")

    # 임시 파일에 JSON 데이터 저장 (긴 데이터 처리를 위해)
    temp_file = Tempfile.new([ "python_input", ".json" ])
    begin
      temp_file.write(json_input)
      temp_file.close

      # 파이썬 스크립트 실행 - stdin으로 데이터 전달
      cmd = "cd #{scripts_path} && echo '#{json_input.gsub("'", "\\'")}' | #{python_env_path} rails_integration.py #{command} -"
      Rails.logger.debug "실행 명령어: #{cmd[0..200]}..." # 로그 축약
      
      result = `#{cmd} 2>&1`
      exit_status = $?.exitstatus

      if exit_status != 0
        raise "파이썬 스크립트 실행 실패 (exit code: #{exit_status}): #{result}"
      end

      result

    ensure
      temp_file.unlink
    end
  end

  def validate_job_data(data)
    {
      company_name: data[:company_name] || data["company_name"] || "",
      position: data[:position] || data["position"] || "",
      title: data[:title] || data["title"] || "",
      content: data[:content] || data["content"] || "",
      html_content: data[:html_content] || data["html_content"] || "",
      url: data[:url] || data["url"] || "",
      location: data[:location] || data["location"] || "",
      salary: data[:salary] || data["salary"] || "",
      requirements: data[:requirements] || data["requirements"] || "",
      benefits: data[:benefits] || data["benefits"] || "",
      collected_at: data[:collected_at] || data["collected_at"] || Time.current.iso8601
    }
  end

  def validate_company_data(data)
    {
      name: data[:name] || data["name"] || "",
      founded: data[:founded] || data["founded"] || "",
      location: data[:location] || data["location"] || "",
      ceo: data[:ceo] || data["ceo"] || "",
      employees: data[:employees] || data["employees"] || "",
      description: data[:description] || data["description"] || "",
      business_areas: data[:business_areas] || data["business_areas"] || "",
      website: data[:website] || data["website"] || "",
      industry: data[:industry] || data["industry"] || "",
      news_data: data[:news_data] || data["news_data"] || [],
      financial_data: data[:financial_data] || data["financial_data"] || {},
      job_postings: data[:job_postings] || data["job_postings"] || [],
      culture_description: data[:culture_description] || data["culture_description"] || "",
      values: data[:values] || data["values"] || "",
      benefits: data[:benefits] || data["benefits"] || "",
      competitors: data[:competitors] || data["competitors"] || []
    }
  end

  def collect_job_posting_data_with_playwright(url)
    # 실제 구현에서는 플레이라이트 MCP 도구들을 사용
    # 여기서는 예시 구조만 제공
    {
      data: {
        url: url,
        company_name: "수집된 회사명",
        position: "수집된 직무명",
        content: "수집된 채용공고 내용",
        html_content: "수집된 HTML 내용"
      },
      metadata: {
        crawled_at: Time.current.iso8601,
        source_url: url,
        crawling_method: "playwright_mcp"
      }
    }
  end

  def collect_basic_company_info(company_name)
    # 기업 기본 정보 수집 (예: 공식 홈페이지, 위키피디아 등)
    {}
  end

  def collect_company_news(company_name)
    # 기업 관련 뉴스 수집
    []
  end

  def collect_company_job_postings(company_name)
    # 기업의 채용공고 수집
    []
  end

  def collect_financial_data(company_name)
    # 기업 재무 정보 수집
    {}
  end

  def create_success_response(data)
    {
      success: true,
      data: data,
      timestamp: Time.current.iso8601
    }
  end

  def create_error_response(error_message)
    {
      success: false,
      error: error_message,
      timestamp: Time.current.iso8601
    }
  end
end
