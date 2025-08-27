require "base64"
require "tempfile"

class CoverLettersController < ApplicationController
  before_action :set_cover_letter, only: [ :show, :destroy ]
  skip_before_action :verify_authenticity_token, only: [ :start_interactive, :send_message, :save_interactive, :analyze_job_posting, :analyze_advanced ]

  def index
    @cover_letters = CoverLetter.order(created_at: :desc)
  end

  def new
    @cover_letter = CoverLetter.new
  end

  def interactive
    # 대화형 자소서 작성 페이지
  end

  def advanced
    # 3단계 심층 분석 페이지
    @cover_letter = CoverLetter.new
  end

  def job_posting
    # 채용공고 URL 분석 페이지
    # 북마크릿에서 자동 실행 지원
    if params[:url].present? && params[:auto_analyze] == "true"
      @auto_url = params[:url]
      @auto_analyze = true
    end
  end

  def bookmarklet
    # 북마크릿 설치 페이지
  end

  def job_posting_text
    # 채용공고 텍스트 직접 입력 페이지
  end

  def saved_job_analyses
    @job_analyses = if current_user
                      JobAnalysis.where(user_id: current_user.id).order(created_at: :desc)
    else
                      JobAnalysis.where(session_id: session.id.to_s).order(created_at: :desc)
    end
    @job_analyses = @job_analyses.page(params[:page]).per(10)

    respond_to do |format|
      format.html # saved_job_analyses.html.erb
      format.json do
        render json: {
          analyses: @job_analyses.map do |analysis|
            {
              id: analysis.id,
              company_name: analysis.company_name,
              position: analysis.position,
              keywords: analysis.keywords,
              summary: analysis.summary,
              created_at: analysis.created_at
            }
          end
        }
      end
    end
  end

  def save_job_analysis
    job_analysis = JobAnalysis.find(params[:id])

    if current_user
      job_analysis.update!(user_id: current_user.id, saved: true)
    else
      job_analysis.update!(session_id: session.id.to_s, saved: true)
    end

    respond_to do |format|
      format.json { render json: { success: true, message: "채용공고 분석이 저장되었습니다." } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { success: false, error: "분석을 찾을 수 없습니다." }, status: 404 }
    end
  rescue => e
    Rails.logger.error "Save job analysis error: #{e.message}"
    respond_to do |format|
      format.json { render json: { success: false, error: e.message }, status: 422 }
    end
  end

  def view_job_analysis
    @job_analysis = JobAnalysis.find(params[:id])

    # 권한 확인
    if current_user
      unless @job_analysis.user_id == current_user.id
        redirect_to saved_job_analyses_cover_letters_path, alert: "권한이 없습니다."
        nil
      end
    else
      unless @job_analysis.session_id == session.id.to_s
        redirect_to saved_job_analyses_cover_letters_path, alert: "권한이 없습니다."
        nil
      end
    end
  end

  def delete_job_analysis
    @job_analysis = JobAnalysis.find(params[:id])

    # 권한 확인
    if current_user
      unless @job_analysis.user_id == current_user.id
        respond_to do |format|
          format.html { redirect_to saved_job_analyses_cover_letters_path, alert: "권한이 없습니다." }
          format.json { render json: { success: false, error: "권한이 없습니다." }, status: 403 }
        end
        return
      end
    else
      unless @job_analysis.session_id == session.id.to_s
        respond_to do |format|
          format.html { redirect_to saved_job_analyses_cover_letters_path, alert: "권한이 없습니다." }
          format.json { render json: { success: false, error: "권한이 없습니다." }, status: 403 }
        end
        return
      end
    end

    # 삭제 실행
    @job_analysis.destroy

    respond_to do |format|
      format.html { redirect_to saved_job_analyses_cover_letters_path, notice: "채용공고 분석이 삭제되었습니다." }
      format.json { render json: { success: true, message: "채용공고 분석이 삭제되었습니다." } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to saved_job_analyses_cover_letters_path, alert: "분석을 찾을 수 없습니다." }
      format.json { render json: { success: false, error: "분석을 찾을 수 없습니다." }, status: 404 }
    end
  end

  def company_analysis
    # 기업 분석 페이지
    @recent_analyses = CompanyAnalysis.recent.order(analysis_date: :desc).limit(10)
  end

  def analyze_company
    company_name = params[:company_name]
    analysis_type = params[:analysis_type] || "enhanced"
    force_refresh = params[:force_refresh] == "true"

    # 캐시된 분석이 있는지 확인 (구직자 맞춤 분석)
    unless force_refresh
      existing_analysis = CompanyAnalysis.by_company(company_name).recent.first

      if existing_analysis
        Rails.logger.info "📋 캐시된 분석 결과 사용: #{existing_analysis.id}"
        redirect_to company_analysis_result_cover_letters_path(existing_analysis)
        return
      end
    end



    # 파이썬 AI 분석 처리
    if analysis_type == "python_ai"
      begin
        Rails.logger.info "🐍 파이썬 AI 정량 분석 시작"
        python_service = PythonAnalysisService.new
        result = python_service.analyze_company_with_comprehensive_data(company_name)

        if result[:success]
          # 분석 결과 저장
          company_analysis = CompanyAnalysis.create!(
            company_name: company_name,
            industry: result[:data][:industry][:primary_industry] || "일반",
            company_size: result[:data][:company_size][:estimated_size] || "중소기업",
            recent_issues: result[:data][:news_sentiment].to_json,
            business_context: result[:data][:basic_info].to_json,
            hiring_patterns: result[:data][:hiring_trends].to_json,
            analysis_date: Time.current,
            cached_until: 7.days.from_now,
            user_id: current_user&.id,
            session_id: session.id.to_s,
            metadata: {
              overall_score: result[:data][:overall_score],
              analysis_type: "python_ai",
              analysis_version: "4.0",
              python_analysis_data: result[:data],
              job_seeker_focused: true
            }
          )

          Rails.logger.info "✅ 파이썬 AI 분석 완료"
          redirect_to company_analysis_result_cover_letters_path(company_analysis)
          return
        else
          Rails.logger.error "❌ 파이썬 AI 분석 실패: #{result[:error]}"
          redirect_to company_analysis_cover_letters_path, alert: "AI 분석 실패: #{result[:error]}"
          return
        end
      rescue => e
        Rails.logger.error "Python AI 분석 오류: #{e.message}"
        redirect_to company_analysis_cover_letters_path, alert: "AI 분석 중 오류가 발생했습니다."
        return
      end
    end

    # 실시간 웹 분석 (enhanced) - 구직자 맞춤 정보 제공
    if analysis_type == "enhanced"
      # 강화 분석: 웹 크롤링 기반 심층 분석
      Rails.logger.info "🚀 Starting enhanced analysis with web scraping for: #{company_name}"
      service = EnhancedCompanyAnalyzerService.new(company_name)
      analysis_result = service.perform_enhanced_analysis

      # 분석 결과 저장 (캐시)
      company_analysis = CompanyAnalysis.create!(
        company_name: company_name,
        industry: extract_industry_from_analysis(analysis_result[:company_overview]),
        company_size: detect_company_size(company_name),
        recent_issues: analysis_result[:industry_market].to_json,
        business_context: analysis_result[:hiring_strategy].to_json,
        hiring_patterns: analysis_result[:job_preparation].to_json,
        competitor_info: analysis_result[:competitor_comparison].to_json,
        industry_trends: analysis_result[:consultant_advice].to_json,
        analysis_date: Time.current,
        cached_until: 7.days.from_now,
        user_id: current_user&.id,
        session_id: session.id.to_s,
        saved: false, # 초기에는 저장되지 않은 상태
        metadata: {
          executive_summary: analysis_result[:executive_summary],
          company_overview: analysis_result[:company_overview],
          hiring_strategy: analysis_result[:hiring_strategy],
          job_preparation: analysis_result[:job_preparation],
          consultant_advice: analysis_result[:consultant_advice],
          analysis_type: "job_seeker_focused",
          analysis_version: "3.0",
          methodology: analysis_result[:metadata][:methodology]
        }
      )

      redirect_to company_analysis_result_cover_letters_path(company_analysis)
    end
  rescue => e
    Rails.logger.error "Company analysis failed: #{e.message}"
    redirect_to company_analysis_cover_letters_path, alert: "기업 분석 중 오류가 발생했습니다: #{e.message}"
  end

  def company_analysis_result
    if params[:id] == "0"
      # 임시 분석 결과 (기본 분석)
      temp_analysis = session[:temp_company_analysis]
      @company_analysis = CompanyAnalysis.new(temp_analysis)
      @structured_data = @company_analysis.structured_data
      @is_basic_analysis = true
    else
      # 저장된 분석 결과 (강화 분석)
      @company_analysis = CompanyAnalysis.find(params[:id])
      @structured_data = @company_analysis.structured_data
      @is_basic_analysis = false
    end
  end

  def save_company_analysis
    @company_analysis = CompanyAnalysis.find(params[:id])

    # 권한 확인
    if current_user
      @company_analysis.update!(user_id: current_user.id, saved: true)
    else
      @company_analysis.update!(session_id: session.id.to_s, saved: true)
    end

    respond_to do |format|
      format.json { render json: { success: true, message: "기업 분석이 저장되었습니다." } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { success: false, error: "분석을 찾을 수 없습니다." }, status: 404 }
    end
  rescue => e
    Rails.logger.error "Save company analysis error: #{e.message}"
    respond_to do |format|
      format.json { render json: { success: false, error: e.message }, status: 422 }
    end
  end

  def delete_company_analysis
    @company_analysis = CompanyAnalysis.find(params[:id])

    # 권한 확인
    # session_id와 user_id가 모두 nil인 경우는 기본 분석이므로 삭제 허용
    if @company_analysis.session_id.nil? && @company_analysis.user_id.nil?
      # 기본 분석은 누구나 삭제 가능
    elsif current_user
      unless @company_analysis.user_id == current_user.id
        render json: { success: false, error: "권한이 없습니다." }, status: 403
        return
      end
    else
      unless @company_analysis.session_id == session.id.to_s
        render json: { success: false, error: "권한이 없습니다." }, status: 403
        return
      end
    end

    @company_analysis.destroy

    respond_to do |format|
      format.html { redirect_to saved_company_analyses_cover_letters_path, notice: "기업 분석이 삭제되었습니다." }
      format.json { render json: { success: true, message: "기업 분석이 삭제되었습니다." } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { success: false, error: "분석을 찾을 수 없습니다." }, status: 404 }
    end
  end

  def saved_company_analyses
    @company_analyses = if current_user
                          CompanyAnalysis.where(user_id: current_user.id)
    else
                          CompanyAnalysis.where(session_id: session.id.to_s)
    end
    @company_analyses = @company_analyses.order(created_at: :desc).page(params[:page]).per(10)
  end

  def load_job_analysis
    job_analysis = JobAnalysis.find(params[:id])

    # 권한 확인
    if current_user
      unless job_analysis.user_id == current_user.id
        render json: { success: false, error: "권한이 없습니다." }, status: 403
        return
      end
    else
      unless job_analysis.session_id == session.id.to_s
        render json: { success: false, error: "권한이 없습니다." }, status: 403
        return
      end
    end

    render json: {
      success: true,
      job_analysis: job_analysis.as_json(
        only: [ :id, :company_name, :position, :keywords, :required_skills,
               :company_values, :summary, :analysis_result, :created_at ]
      )
    }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "분석을 찾을 수 없습니다." }, status: 404
  end

  def ontology_input
    # 온톨로지 분석 입력 페이지
    @job_analysis = JobAnalysis.find(params[:job_analysis_id]) if params[:job_analysis_id]
    @user_profile = current_user&.user_profile
  end

  def intelligent_analysis
    # 지능형 맥락 분석 페이지
    @user_profile = current_user&.user_profile
    @recent_job_analyses = JobAnalysis.order(created_at: :desc).limit(5)
  end

  def perform_intelligent_analysis
    begin
      # 지능형 자소서 생성
      service = IntelligentCoverLetterGeneratorService.new(
        current_user.user_profile,
        params[:job_posting_url] || params[:job_posting_data],
        params[:company_name]
      )

      result = service.generate

      # 결과 저장
      cover_letter = CoverLetter.create!(
        user: current_user,
        company_name: params[:company_name],
        position: params[:position],
        content: result[:cover_letter],
        analysis_type: "intelligent",
        insights: result[:insights],
        metadata: result[:metadata]
      )

      render json: {
        success: true,
        cover_letter_id: cover_letter.id,
        content: result[:cover_letter],
        insights: result[:insights],
        metadata: result[:metadata]
      }
    rescue => e
      Rails.logger.error "Intelligent analysis failed: #{e.message}"
      render json: { success: false, error: e.message }, status: 422
    end
  end

  def ontology_analysis
    if request.post?
      # 온톨로지 분석 실행
      service = UnifiedOntologyService.new(
        params[:job_analysis_id],
        params[:user_profile_id]
      )

      @analysis_result = service.perform_analysis
      @visualization_data = service.generate_visualization_data(@analysis_result.matching_result)

      render :ontology_analysis
    else
      # GET 요청: 분석 결과 페이지
      @analysis = OntologyAnalysis.find(params[:id]) if params[:id]
    end
  end

  def analyze_job_text
    # Enhanced 분석 사용 여부 결정 (기본값: true)
    use_enhanced = params[:use_enhanced] != "false"

    if use_enhanced
      # 강화된 채용공고 분석 서비스 사용
      enhanced_service = EnhancedJobPostingAnalyzerService.new
      result = enhanced_service.perform_deep_analysis(
        params[:company_name],
        params[:position],
        params[:content],
        params[:source_url]
      )

      if result
        # 분석 결과를 데이터베이스에 저장
        job_analysis = JobAnalysis.create!(
          url: params[:source_url] || "text_input",
          company_name: params[:company_name],
          position: params[:position],
          analysis_result: result.to_json,
          user_id: current_user&.id,
          session_id: current_user ? nil : session.id.to_s
        )

        # 키 정보 추출
        job_analysis.extract_key_info
        job_analysis.save

        # 세션에는 ID만 저장
        session[:job_analysis_id] = job_analysis.id

        render json: {
          success: true,
          analysis: result,
          analysis_id: job_analysis.id,
          is_enhanced: true
        }
      else
        render json: {
          success: false,
          error: "강화 분석 중 오류가 발생했습니다"
        }, status: :unprocessable_entity
      end
    else
      # 기존 분석 서비스 사용 (폴백)
      service = JobPostingAnalyzerService.new
      result = service.analyze_job_text(
        params[:company_name],
        params[:position],
        params[:content],
        params[:source_url]
      )

      if result[:success]
        # 분석 결과를 데이터베이스에 저장
        job_analysis = JobAnalysis.create!(
          url: params[:source_url] || "text_input",
          company_name: params[:company_name],
          position: params[:position],
          analysis_result: result[:analysis],
          user_id: current_user&.id,
          session_id: current_user ? nil : session.id.to_s
        )

        # 키 정보 추출
        job_analysis.extract_key_info
        job_analysis.save

        # 세션에는 ID만 저장
        session[:job_analysis_id] = job_analysis.id

        render json: {
          success: true,
          analysis: result[:analysis],
          analysis_id: job_analysis.id,
          is_enhanced: false
        }
      else
        render json: {
          success: false,
          error: result[:error]
        }, status: :unprocessable_entity
      end
    end
  end

  def analyze_job_posting
    begin
      url = params[:url]
      job_title = params[:job_title]
      # 강화된 분석을 기본값으로 사용 (명시적으로 false가 아닌 경우)
      use_enhanced = params[:use_enhanced] != "false"
      use_python = params[:use_python] == "true"
      use_mcp = params[:use_mcp] != "false"  # MCP 기본 사용

      Rails.logger.info "URL: #{url}, Job Title: #{job_title}, Enhanced: #{use_enhanced}, Python: #{use_python}, MCP: #{use_mcp}"

      # 사람인 URL인 경우 MCP 스냅샷 방식 우선 사용
      if url.include?("saramin.co.kr") && use_mcp
        begin
          Rails.logger.info "🎯 사람인 URL 감지 - MCP 스냅샷 분석 시작"
          mcp_service = McpJobAnalyzerService.new
          mcp_result = mcp_service.analyze_with_snapshot(url)

          if mcp_result[:success]
            Rails.logger.info "✅ MCP 스냅샷 분석 성공"

            # 분석 결과 저장
            job_analysis = JobAnalysis.create!(
              url: url,
              company_name: mcp_result[:data][:basic_info][:company_name],
              position: mcp_result[:data][:basic_info][:position],
              analysis_result: mcp_result[:data].to_json,
              analysis_type: "mcp_snapshot",
              user_id: current_user&.id,
              session_id: current_user ? nil : session.id.to_s
            )

            render json: {
              success: true,
              analysis: mcp_result[:data][:analysis_result],
              analysis_data: mcp_result[:data],
              company_name: mcp_result[:data][:basic_info][:company_name],
              position: mcp_result[:data][:basic_info][:position],
              job_analysis_id: job_analysis.id,
              analysis_type: "mcp_snapshot",
              snapshot_captured: true
            }
            return
          else
            Rails.logger.warn "MCP 분석 실패, 파이썬 방식으로 폴백: #{mcp_result[:error]}"
          end
        rescue => mcp_error
          Rails.logger.error "MCP 분석 오류: #{mcp_error.message}"
        end
      end

      # 파이썬 분석 시도 (MCP 실패시 폴백)
      if use_python
        begin
          python_service = PythonAnalysisService.new
          python_result = python_service.analyze_job_posting_with_playwright(url)

          if python_result[:success]
            Rails.logger.info "파이썬 분석 성공"

            # 분석 결과를 데이터베이스에 저장
            job_analysis = JobAnalysis.create!(
              url: url,
              company_name: python_result[:data][:analysis_result][:basic_info][:company_name],
              position: python_result[:data][:analysis_result][:basic_info][:position],
              analysis_result: python_result[:data].to_json,
              analysis_type: "python_enhanced",
              user_id: current_user&.id,
              session_id: current_user ? nil : session.id.to_s
            )

            render json: {
              success: true,
              analysis: python_result[:data][:analysis_result][:report],
              analysis_data: python_result[:data][:analysis_result],
              company_name: python_result[:data][:analysis_result][:basic_info][:company_name],
              position: python_result[:data][:analysis_result][:basic_info][:position],
              job_analysis_id: job_analysis.id,
              analysis_type: "python_enhanced"
            }
            return
          else
            Rails.logger.warn "파이썬 분석 실패, 기존 방식으로 폴백: #{python_result[:error]}"
          end
        rescue => python_error
          Rails.logger.error "파이썬 분석 오류: #{python_error.message}"
        end
      end

      if use_enhanced
        # 강화된 채용공고 분석 서비스 사용
        Rails.logger.info "Using Enhanced Job Posting Analyzer Service"

        # 먼저 기본 크롤링으로 정보 추출
        basic_service = JobPostingAnalyzerService.new
        crawl_result = basic_service.analyze_job_posting(url, job_title)

        if crawl_result[:success]
          # 크롤링된 내용에서 회사명과 포지션 추출
          analysis_text = crawl_result[:analysis]
          company_name = extract_company_from_analysis(analysis_text) || extract_company_from_url(url)
          position = extract_position_from_analysis(analysis_text) || job_title

          Rails.logger.info "Extracted - Company: #{company_name}, Position: #{position}"

          # 강화된 분석 수행
          enhanced_service = EnhancedJobPostingAnalyzerService.new
          enhanced_result = enhanced_service.perform_deep_analysis(
            company_name || "회사명 미상",
            position || "포지션 미상",
            crawl_result[:raw_content] || analysis_text,
            url
          )

          if enhanced_result
            # 분석 결과를 데이터베이스에 저장
            job_analysis = JobAnalysis.create!(
              url: url,
              company_name: enhanced_result[:company_name],
              position: enhanced_result[:position],
              analysis_result: enhanced_result.to_json,
              user_id: current_user&.id,
              session_id: current_user ? nil : session.id.to_s
            )

            # 키 정보 추출
            job_analysis.extract_key_info
            job_analysis.save

            # 세션에는 ID만 저장
            session[:job_analysis_id] = job_analysis.id

            render json: {
              success: true,
              analysis: enhanced_result,
              analysis_id: job_analysis.id,
              is_enhanced: true
            }
          else
            # 강화 분석 실패시 기본 분석 결과 사용
            Rails.logger.warn "Enhanced analysis failed, falling back to basic analysis"
            render json: {
              success: true,
              analysis: crawl_result[:analysis],
              is_enhanced: false,
              fallback_reason: "강화 분석이 실패하여 기본 분석 결과를 제공합니다."
            }
          end
        else
          render json: {
            success: false,
            error: crawl_result[:error] || "채용공고를 가져올 수 없습니다"
          }, status: :unprocessable_entity
        end
      else
        # 기존 분석 서비스 사용
        service = JobPostingAnalyzerService.new
        result = service.analyze_job_posting(url, job_title)

        if result[:success]
          # 분석 결과를 데이터베이스에 저장
          job_analysis = JobAnalysis.create!(
            url: result[:url],
            analysis_result: result[:analysis],
            user_id: current_user&.id,
            session_id: current_user ? nil : session.id.to_s
          )

          # 키 정보 추출
          job_analysis.extract_key_info
          job_analysis.save

          # 세션에는 ID만 저장 (쿠키 오버플로우 방지)
          session[:job_analysis_id] = job_analysis.id

          render json: {
            success: true,
            analysis: result[:analysis],
            analysis_id: job_analysis.id,
            is_advanced: false
          }
        else
          render json: {
            success: false,
            error: result[:error]
          }, status: :unprocessable_entity
        end
      end
    rescue => e
      Rails.logger.error "채용공고 분석 컨트롤러 오류: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n") if e.backtrace

      render json: {
        success: false,
        error: "분석 중 오류가 발생했습니다: #{e.message}"
      }, status: :unprocessable_entity
    end
  end

  def analyze_advanced
    # pdf_content는 DB 필드가 아니므로 별도로 처리
    permitted_params = params.require(:cover_letter).permit(:title, :content, :company_name, :position, :user_name)
    @cover_letter = CoverLetter.new(permitted_params)

    # PDF 처리
    pdf_analysis = nil
    if params[:cover_letter][:pdf_content].present?
      begin
        # Base64 디코딩
        pdf_data = params[:cover_letter][:pdf_content]
        pdf_data = pdf_data.sub(/^data:application\/pdf;base64,/, "")

        # 임시 파일로 저장
        temp_file = Tempfile.new([ "resume", ".pdf" ])
        temp_file.binmode
        temp_file.write(Base64.decode64(pdf_data))
        temp_file.rewind

        # PDF 분석
        pdf_service = PdfAnalyzerService.new(temp_file.path)
        pdf_analysis = pdf_service.analyze_resume

        # 분석 결과를 자소서에 추가
        if pdf_analysis[:success]
          enhanced_content = "#{@cover_letter.content}\n\n--- PDF 분석 내용 ---\n#{pdf_analysis[:extracted_text][0..2000]}"
          @cover_letter.content = enhanced_content
        end

        temp_file.close
        temp_file.unlink
      rescue => e
        Rails.logger.error "PDF Processing Error: #{e.message}"
      end
    end

    if @cover_letter.save
      # 자소서 분석만 실행 (기업 분석 제외)
      service = AdvancedCoverLetterService.new
      result = service.analyze_cover_letter_only(@cover_letter.content)

      if result[:success]
        analysis_with_pdf = result[:full_analysis]

        # PDF 분석 결과 추가
        if pdf_analysis && pdf_analysis[:success]
          analysis_with_pdf += "\n\n## PDF 이력서 분석 결과\n#{pdf_analysis[:analysis][:combined] rescue pdf_analysis[:analysis]}"
        end

        # deep_analysis_data에 PDF 구조화 분석 결과 저장
        deep_analysis_data = {}
        if pdf_analysis && pdf_analysis[:success]
          deep_analysis_data[:pdf_analysis] = pdf_analysis
        end
        
        # Python NLP 분석 결과 추가
        if result[:python_analysis].present?
          deep_analysis_data[:python_analysis] = result[:python_analysis]
        end

        @cover_letter.update(
          analysis_result: analysis_with_pdf,
          deep_analysis_data: deep_analysis_data
        )
        redirect_to @cover_letter, notice: "3\uB2E8\uACC4 \uC2EC\uCE35 \uBD84\uC11D\uC774 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4."
      else
        @cover_letter.update(analysis_result: "분석 실패: #{result[:error]}")
        redirect_to @cover_letter, alert: "분석 중 오류가 발생했습니다: #{result[:error]}"
      end
    else
      render :advanced
    end
  end

  # GPT-5 심층 분석 - 사용하지 않음
  # def deep_analysis
  #   # 심층 분석 입력 페이지
  #   @cover_letter = CoverLetter.new
  #   @user_profile = current_user&.user_profile
  # end

  # def perform_deep_analysis
  #   @cover_letter = CoverLetter.new(cover_letter_params)
  #
  #   if @cover_letter.save
  #     # GPT-5 심층 분석 실행
  #     service = DeepAnalysisService.new
  #     user_profile = current_user&.user_profile
  #
  #     result = service.perform_deep_analysis(
  #       @cover_letter.content,
  #       @cover_letter.company_name,
  #       @cover_letter.position,
  #       user_profile
  #     )
  #
  #     if result[:success]
  #       # 분석 결과 저장
  #       @cover_letter.update(
  #         analysis_result: result[:comprehensive_report],
  #         deep_analysis_data: result[:analyses]
  #       )
  #
  #       # 분석 결과 페이지로 이동
  #       redirect_to deep_analysis_result_cover_letter_path(@cover_letter)
  #     else
  #       @cover_letter.update(analysis_result: "분석 실패: #{result[:error]}")
  #       redirect_to @cover_letter, alert: "분석 중 오류가 발생했습니다: #{result[:error]}"
  #     end
  #   else
  #     render :deep_analysis
  #   end
  # end

  # def deep_analysis_result
  #   @cover_letter = CoverLetter.find(params[:id])
  #   @analysis_data = @cover_letter.deep_analysis_data
  #   @comprehensive_report = @cover_letter.analysis_result
  #
  #   # 시각화를 위한 데이터 준비
  #   if @analysis_data
  #     service = DeepAnalysisService.new
  #     @visualization_data = service.send(:prepare_visualization_data, @analysis_data)
  #   end
  # end

  def rewrite_with_feedback
    @cover_letter = CoverLetter.find(params[:id])

    # 서비스 초기화
    service = AdvancedCoverLetterService.new

    # 기존 분석 결과에서 자소서 분석 부분만 추출 (기업 분석 제외)
    existing_analysis = @cover_letter.analysis_result || ""

    # 피드백 기반 리라이트 실행 (기업 분석 제외)
    result = service.rewrite_with_feedback_only(
      @cover_letter.content,
      existing_analysis,  # 2단계 분석 결과를 피드백으로 사용
      @cover_letter.company_name,
      @cover_letter.position
    )

    if result[:success]
      # 결과 저장 (advanced_analysis 필드에 저장)
      @cover_letter.update(
        advanced_analysis: result[:rewritten_letter]
      )

      redirect_to rewrite_result_cover_letter_path(@cover_letter)
    else
      redirect_to @cover_letter, alert: result[:error] || "리라이트 중 오류가 발생했습니다"
    end
  rescue => e
    Rails.logger.error "Rewrite error: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    redirect_to @cover_letter, alert: "자기소개서 리라이트 중 오류가 발생했습니다: #{e.message}"
  end

  def rewrite_result
    @cover_letter = CoverLetter.find(params[:id])
    @rewritten_content = @cover_letter.advanced_analysis

    unless @rewritten_content
      redirect_to @cover_letter, alert: "리라이트된 자기소개서가 없습니다."
    end
  end

  def start_interactive
    service = InteractiveCoverLetterService.new
    session_data = service.start_conversation(
      params[:company_name],
      params[:position]
    )

    # 데이터베이스에 저장
    chat_session = ChatSession.create!(
      company_name: params[:company_name],
      position: params[:position],
      current_step: session_data[:current_step],
      content: session_data[:content] || {},
      messages: session_data[:messages] || [],
      question_count: {}
    )

    session[:chat_session_id] = chat_session.session_id

    render json: {
      success: true,
      current_step: session_data[:current_step],
      message: session_data[:messages].last[:content],
      progress: 14 # 1/7 steps
    }
  end

  def send_message
    # 데이터베이스에서 세션 로드
    chat_session = ChatSession.find_by(session_id: session[:chat_session_id])

    unless chat_session
      render json: { success: false, error: "\uC138\uC158\uC744 \uCC3E\uC744 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4" }, status: 404
      return
    end

    # 세션 데이터 복원
    session_data = {
      "company_name" => chat_session.company_name,
      "position" => chat_session.position,
      "current_step" => chat_session.current_step,
      "content" => chat_session.content || {},
      "messages" => chat_session.messages || [],
      "question_count" => chat_session.question_count || {}
    }

    service = InteractiveCoverLetterService.new
    result = service.process_message(
      session_data,
      params[:message]
    )

    # 데이터베이스 업데이트
    chat_session.update!(
      current_step: result[:session_data]["current_step"],
      content: result[:session_data]["content"],
      messages: result[:session_data]["messages"],
      question_count: result[:session_data]["question_count"],
      final_content: result[:session_data]["final_content"]
    )

    # Python 분석 결과 포함
    quality_scores = result[:session_data]["quality_scores"] || []
    latest_score = quality_scores.last

    render json: {
      success: true,
      current_step: result[:current_step],
      message: result[:response],
      progress: result[:progress],
      final_content: result[:session_data]["final_content"],
      quality_analysis: latest_score
    }
  end

  def save_interactive
    chat_session = ChatSession.find_by(session_id: session[:chat_session_id])

    unless chat_session
      render json: { success: false, error: "\uC138\uC158\uC744 \uCC3E\uC744 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4" }, status: 404
      return
    end

    @cover_letter = CoverLetter.new(
      title: params[:title],
      content: params[:content],
      company_name: chat_session.company_name,
      position: chat_session.position,
      user_name: params[:user_name]
    )

    if @cover_letter.save
      chat_session.destroy # 세션 정리
      session.delete(:chat_session_id)
      render json: { success: true, redirect_url: cover_letter_path(@cover_letter) }
    else
      render json: { success: false, errors: @cover_letter.errors.full_messages }
    end
  end

  def create
    @cover_letter = CoverLetter.new(cover_letter_params)

    if @cover_letter.save
      # 분석 유형에 따라 서비스 선택
      if params[:analysis_type] == "advanced"
        # 3단계 고급 분석
        service = AdvancedCoverLetterService.new
        result = service.analyze_complete(
          @cover_letter.content,
          @cover_letter.company_name,
          @cover_letter.position
        )

        if result[:success]
          @cover_letter.update(analysis_result: result[:full_analysis])
          redirect_to @cover_letter, notice: "3\uB2E8\uACC4 \uC2EC\uCE35 \uBD84\uC11D\uC774 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4."
        else
          @cover_letter.update(analysis_result: "분석 실패: #{result[:error]}")
          redirect_to @cover_letter, alert: "분석 중 오류가 발생했습니다: #{result[:error]}"
        end
      else
        # 기본 분석
        service = OpenaiService.new
        result = service.analyze_cover_letter(
          @cover_letter.content,
          @cover_letter.company_name,
          @cover_letter.position
        )

        if result[:success]
          @cover_letter.update(analysis_result: result[:analysis])
          redirect_to @cover_letter, notice: "\uC790\uAE30\uC18C\uAC1C\uC11C \uBD84\uC11D\uC774 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4."
        else
          @cover_letter.update(analysis_result: "분석 실패: #{result[:error]}")
          redirect_to @cover_letter, alert: "분석 중 오류가 발생했습니다: #{result[:error]}"
        end
      end
    else
      render :new
    end
  end

  def show
    @analysis_sections = parse_analysis(@cover_letter.analysis_result) if @cover_letter.analysis_result
  end

  def destroy
    @cover_letter.destroy
    redirect_to cover_letters_path, notice: "\uC790\uAE30\uC18C\uAC1C\uC11C\uAC00 \uC0AD\uC81C\uB418\uC5C8\uC2B5\uB2C8\uB2E4."
  end

  def guide
    # 사용 가이드 페이지
  end

  private

  def set_cover_letter
    @cover_letter = CoverLetter.find(params[:id])
  end

  def cover_letter_params
    params.require(:cover_letter).permit(:title, :content, :company_name, :position, :user_name)
  end

  def parse_analysis(analysis_text)
    return nil unless analysis_text

    sections = {
      overall_score: extract_score(analysis_text),
      strengths: extract_section(analysis_text, "\uAC15\uC810"),
      improvements: extract_section(analysis_text, "\uAC1C\uC120"),
      structure: extract_section(analysis_text, "\uAD6C\uC870"),
      specificity: extract_section(analysis_text, "\uAD6C\uCCB4\uC131"),
      job_fit: extract_section(analysis_text, "\uC9C1\uBB34"),
      differentiation: extract_section(analysis_text, "\uCC28\uBCC4\uD654"),
      writing: extract_section(analysis_text, "\uBB38\uC7A5\uB825"),
      suggestions: extract_section(analysis_text, "\uAC1C\uC120 \uC81C\uC548"),
      keywords: extract_keywords(analysis_text)
    }

    sections
  end

  def extract_score(text)
    match = text.match(/(\d+)점/)
    match ? match[1].to_i : nil
  end

  def extract_section(text, keyword)
    # 간단한 섹션 추출 로직
    lines = text.split("\n")
    section_lines = []
    in_section = false

    lines.each do |line|
      if line.include?(keyword)
        in_section = true
        next
      elsif line.match(/^\d+\./) && in_section
        break
      elsif in_section
        section_lines << line unless line.strip.empty?
      end
    end

    section_lines
  end

  def extract_keywords(text)
    keyword_section = text.match(/추천 키워드.*?$(.*?)^(?=\d+\.|$)/m)
    return [] unless keyword_section

    keyword_section[1].scan(/[가-힣]+/).uniq
  end

  def extract_company_from_analysis(analysis_text)
    return nil unless analysis_text

    # 기업명 추출 패턴
    if analysis_text.match(/기업명\*?\*?:\s*([^\n]+)/)
      return $1.strip.gsub(/\*/, "")
    elsif analysis_text.match(/회사:\s*([^\n]+)/)
      return $1.strip
    end

    nil
  end

  def extract_position_from_analysis(analysis_text)
    return nil unless analysis_text

    # 직무 추출 패턴
    if analysis_text.match(/모집 직무\*?\*?:\s*([^\n]+)/)
      return $1.strip.gsub(/\*/, "")
    elsif analysis_text.match(/직무:\s*([^\n]+)/)
      return $1.strip
    elsif analysis_text.match(/포지션:\s*([^\n]+)/)
      return $1.strip
    end

    nil
  end

  def detect_company_size(company_name)
    large_companies = [ "\uC0BC\uC131", "Samsung", "\uD604\uB300", "Hyundai", "LG", "SK", "\uB86F\uB370", "Lotte",
                      "\uD55C\uD654", "Hanwha", "GS", "\uC2E0\uC138\uACC4", "CJ", "\uB450\uC0B0", "Doosan",
                      "\uD3EC\uC2A4\uCF54", "POSCO", "\uCE74\uCE74\uC624", "Kakao", "\uB124\uC774\uBC84", "Naver",
                      "KT", "KB", "\uC2E0\uD55C", "\uD558\uB098", "\uC6B0\uB9AC", "NH\uB18D\uD611", "\uD604\uB300\uCC28", "\uAE30\uC544" ]

    normalized_name = company_name.downcase.gsub(/[\(\)\.주식회사㈜]/, "")

    if large_companies.any? { |keyword| normalized_name.include?(keyword.downcase) }
      "\uB300\uAE30\uC5C5"
    elsif company_name.include?("\uC2A4\uD0C0\uD2B8\uC5C5") || company_name.include?("\uBCA4\uCC98")
      "\uC2A4\uD0C0\uD2B8\uC5C5"
    else
      "\uC911\uACAC/\uC911\uC18C\uAE30\uC5C5"
    end
  end

  def perform_basic_company_analysis(company_name)
    # 기본 분석: 간단한 AI 프롬프트로 빠른 분석
    require "net/http"
    require "json"

    api_key = ENV["OPENAI_API_KEY"]

    prompt = <<~PROMPT
      기업명: #{company_name}

      다음 항목들을 간단히 분석해주세요 (각 2-3문장):
      1. 산업 분야 및 주요 사업
      2. 최근 주요 이슈 (추정)
      3. 비즈니스 현황
      4. 일반적인 채용 패턴

      JSON 형식으로 응답:
      {
        "industry": "산업 분야",
        "recent_issues": {
          "main_topics": ["이슈1", "이슈2"],
          "summary": "요약"
        },
        "business_context": {
          "status": "현황",
          "focus_areas": ["중점 분야"]
        },
        "hiring_patterns": {
          "common_positions": ["직무1", "직무2"],
          "hiring_season": "채용 시즌",
          "requirements": "일반적 요구사항"
        }
      }
    PROMPT

    uri = URI("https://api.openai.com/v1/chat/completions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"

    request.body = {
      model: ENV["OPENAI_MODEL"] || "gpt-4.1",
      messages: [
        { role: "system", content: "\uB2F9\uC2E0\uC740 \uAE30\uC5C5 \uBD84\uC11D \uC804\uBB38\uAC00\uC785\uB2C8\uB2E4. \uC694\uCCAD\uB41C \uD615\uC2DD\uC5D0 \uB9DE\uCDB0 \uC815\uD655\uD558\uAC8C \uC751\uB2F5\uD558\uC138\uC694." },
        { role: "user", content: prompt }
      ],
      temperature: 0.3,
      max_tokens: 1000
    }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)

    if result["choices"]
      content = result["choices"][0]["message"]["content"]
      begin
        parsed_result = JSON.parse(content)
        # 문자열 키를 심볼로 변환
        parsed_result.deep_symbolize_keys
      rescue JSON::ParserError => e
        Rails.logger.error "JSON parsing failed: #{e.message}"
        Rails.logger.error "Content was: #{content}"
        # JSON 파싱 실패 시 기본값 반환
        {
          industry: "타이어 제조업",
          recent_issues: { main_topics: [ "일반 경영 현황" ], summary: "분석 데이터 파싱 실패" },
          business_context: { status: "정상 운영 중", focus_areas: [ "제품 개발" ] },
          hiring_patterns: { common_positions: [ "영업", "생산", "연구개발" ], hiring_season: "상시", requirements: "관련 경력 우대" }
        }
      end
    else
      # API 오류 시 기본값 반환
      {
        industry: "분석 오류",
        recent_issues: { main_topics: [], summary: "분석 오류" },
        business_context: { status: "분석 오류", focus_areas: [] },
        hiring_patterns: { common_positions: [], hiring_season: "알 수 없음", requirements: "분석 오류" }
      }
    end
  rescue => e
    Rails.logger.error "Basic company analysis failed: #{e.message}"
    {
      industry: "오류 발생",
      recent_issues: { main_topics: [], summary: e.message },
      business_context: { status: "오류", focus_areas: [] },
      hiring_patterns: { common_positions: [], hiring_season: "알 수 없음", requirements: "오류" }
    }
  end

  def fetch_competitor_info(company_name)
    # 대기업인 경우에만 경쟁사 정보 수집
    return nil unless detect_company_size(company_name) == "\uB300\uAE30\uC5C5"

    # 간단한 경쟁사 매핑
    competitor_map = {
      "\uC0BC\uC131" => [ "LG", "SK" ],
      "LG" => [ "\uC0BC\uC131", "SK" ],
      "\uD604\uB300" => [ "\uAE30\uC544", "\uC30D\uC6A9" ],
      "\uCE74\uCE74\uC624" => [ "\uB124\uC774\uBC84", "\uB77C\uC778" ],
      "\uB124\uC774\uBC84" => [ "\uCE74\uCE74\uC624", "\uAD6C\uAE00\uCF54\uB9AC\uC544" ],
      "CJ" => [ "\uB86F\uB370", "\uB18D\uC2EC" ],
      "\uB86F\uB370" => [ "CJ", "\uC2E0\uC138\uACC4" ]
    }

    competitors = competitor_map.find { |key, _| company_name.include?(key) }&.last || []
    { competitors: competitors }.to_json
  end

  def extract_company_from_url(url)
    case url
    when /samsungcareers/
      "삼성"
    when /saramin.*company_nm=([^&]+)/
      URI.decode_www_form_component($1) rescue nil
    when /jobkorea.*Co_Name=([^&]+)/
      URI.decode_www_form_component($1) rescue nil
    when /wanted.*company\/([^\/?]+)/
      $1
    else
      nil
    end
  end

  def extract_industry_from_analysis(analysis_text)
    return "분석 중" unless analysis_text

    # 산업 분야 추출 시도
    if analysis_text.match(/산업[:\s]+([^,\n]+)/i)
      return $1.strip
    elsif analysis_text.match(/industry[:\s]+([^,\n]+)/i)
      return $1.strip
    elsif analysis_text.match(/사업[:\s]+([^,\n]+)/i)
      return $1.strip
    end

    "일반 산업"
  end

  # 파이썬 기업 분석 API
  def analyze_company_python
    company_name = params[:company_name]

    if company_name.blank?
      render json: { success: false, error: "회사명이 필요합니다." }
      return
    end

    begin
      python_service = PythonAnalysisService.new
      result = python_service.analyze_company_with_comprehensive_data(company_name)

      if result[:success]
        # 분석 결과 저장
        company_analysis = CompanyAnalysis.create!(
          company_name: company_name,
          analysis_result: result[:data],
          analysis_type: "python_enhanced",
          user: current_user
        )

        render json: {
          success: true,
          analysis: result[:data][:report],
          analysis_data: result[:data],
          analysis_id: company_analysis.id,
          company_name: company_name,
          overall_score: result[:data][:overall_score]
        }
      else
        render json: {
          success: false,
          error: result[:error]
        }
      end

    rescue => e
      Rails.logger.error "기업 분석 오류: #{e.message}"
      render json: {
        success: false,
        error: "분석 중 오류가 발생했습니다."
      }
    end
  end
end
