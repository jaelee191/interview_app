class CoverLettersController < ApplicationController
  before_action :set_cover_letter, only: [:show, :destroy]
  skip_before_action :verify_authenticity_token, only: [:start_interactive, :send_message, :save_interactive, :analyze_job_posting]
  
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
    if params[:url].present? && params[:auto_analyze] == 'true'
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
        return
      end
    else
      unless @job_analysis.session_id == session.id.to_s
        redirect_to saved_job_analyses_cover_letters_path, alert: "권한이 없습니다."
        return
      end
    end
  end
  
  def company_analysis
    # 기업 분석 페이지
    @recent_analyses = CompanyAnalysis.recent.order(analysis_date: :desc).limit(10)
  end
  
  def analyze_company
    company_name = params[:company_name]
    analysis_type = params[:analysis_type] || 'basic'
    force_refresh = params[:force_refresh] == 'true'
    
    # 캐시된 분석이 있는지 확인 (강화 분석만 캐시 사용)
    if analysis_type == 'enhanced'
      existing_analysis = CompanyAnalysis.by_company(company_name).recent.first
      
      if existing_analysis && !force_refresh
        redirect_to company_analysis_result_cover_letters_path(existing_analysis)
        return
      end
    end
    
    # 분석 유형에 따라 다른 처리
    if analysis_type == 'basic'
      # 기본 분석: 간단한 정보만 수집
      analysis_result = perform_basic_company_analysis(company_name)
      
      # 임시 분석 결과 (캐시하지 않음)
      company_analysis = CompanyAnalysis.new(
        company_name: company_name,
        industry: analysis_result[:industry],
        company_size: detect_company_size(company_name),
        recent_issues: analysis_result[:recent_issues].to_json,
        business_context: analysis_result[:business_context].to_json,
        hiring_patterns: analysis_result[:hiring_patterns].to_json,
        analysis_date: Time.current,
        metadata: {
          analysis_type: 'basic',
          analysis_version: '1.0'
        }
      )
      
      # 세션에 임시 저장
      session[:temp_company_analysis] = company_analysis.attributes
      redirect_to company_analysis_result_cover_letters_path(0) # 0은 임시 분석을 의미
      
    else
      # 강화 분석: 구직자 맞춤 취업 컨설팅 심층 분석
      service = JobSeekerCompanyAnalyzerService.new(company_name)
      analysis_result = service.perform_job_seeker_analysis
      
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
          analysis_type: 'job_seeker_focused',
          analysis_version: '3.0',
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
    if params[:id] == '0'
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
        only: [:id, :company_name, :position, :keywords, :required_skills, 
               :company_values, :summary, :analysis_result, :created_at]
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
        analysis_type: 'intelligent',
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
    use_enhanced = params[:use_enhanced] != 'false'
    
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
          analysis_result: result.to_json
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
          analysis_result: result[:analysis]
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
      use_enhanced = params[:use_enhanced] != 'false'
      
      Rails.logger.info "URL: #{url}, Job Title: #{job_title}, Enhanced: #{use_enhanced}"
      
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
              analysis_result: enhanced_result.to_json
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
            analysis_result: result[:analysis]
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
    @cover_letter = CoverLetter.new(cover_letter_params)
    
    if @cover_letter.save
      # 3단계 고급 분석
      service = AdvancedCoverLetterService.new
      result = service.analyze_complete(
        @cover_letter.content,
        @cover_letter.company_name,
        @cover_letter.position
      )
      
      if result[:success]
        @cover_letter.update(analysis_result: result[:full_analysis])
        redirect_to @cover_letter, notice: '3단계 심층 분석이 완료되었습니다.'
      else
        @cover_letter.update(analysis_result: "분석 실패: #{result[:error]}")
        redirect_to @cover_letter, alert: "분석 중 오류가 발생했습니다: #{result[:error]}"
      end
    else
      render :advanced
    end
  end
  
  def deep_analysis
    # 심층 분석 입력 페이지
    @cover_letter = CoverLetter.new
    @user_profile = current_user&.user_profile
  end
  
  def perform_deep_analysis
    @cover_letter = CoverLetter.new(cover_letter_params)
    
    if @cover_letter.save
      # GPT-5 심층 분석 실행
      service = DeepAnalysisService.new
      user_profile = current_user&.user_profile
      
      result = service.perform_deep_analysis(
        @cover_letter.content,
        @cover_letter.company_name,
        @cover_letter.position,
        user_profile
      )
      
      if result[:success]
        # 분석 결과 저장
        @cover_letter.update(
          analysis_result: result[:comprehensive_report],
          deep_analysis_data: result[:analyses]
        )
        
        # 분석 결과 페이지로 이동
        redirect_to deep_analysis_result_cover_letter_path(@cover_letter)
      else
        @cover_letter.update(analysis_result: "분석 실패: #{result[:error]}")
        redirect_to @cover_letter, alert: "분석 중 오류가 발생했습니다: #{result[:error]}"
      end
    else
      render :deep_analysis
    end
  end
  
  def deep_analysis_result
    @cover_letter = CoverLetter.find(params[:id])
    @analysis_data = @cover_letter.deep_analysis_data
    @comprehensive_report = @cover_letter.analysis_result
    
    # 시각화를 위한 데이터 준비
    if @analysis_data
      service = DeepAnalysisService.new
      @visualization_data = service.send(:prepare_visualization_data, @analysis_data)
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
      render json: { success: false, error: '세션을 찾을 수 없습니다' }, status: 404
      return
    end
    
    # 세션 데이터 복원
    session_data = {
      'company_name' => chat_session.company_name,
      'position' => chat_session.position,
      'current_step' => chat_session.current_step,
      'content' => chat_session.content || {},
      'messages' => chat_session.messages || [],
      'question_count' => chat_session.question_count || {}
    }
    
    service = InteractiveCoverLetterService.new
    result = service.process_message(
      session_data,
      params[:message]
    )
    
    # 데이터베이스 업데이트
    chat_session.update!(
      current_step: result[:session_data]['current_step'],
      content: result[:session_data]['content'],
      messages: result[:session_data]['messages'],
      question_count: result[:session_data]['question_count'],
      final_content: result[:session_data]['final_content']
    )
    
    render json: {
      success: true,
      current_step: result[:current_step],
      message: result[:response],
      progress: result[:progress],
      final_content: result[:session_data]['final_content']
    }
  end
  
  def save_interactive
    chat_session = ChatSession.find_by(session_id: session[:chat_session_id])
    
    unless chat_session
      render json: { success: false, error: '세션을 찾을 수 없습니다' }, status: 404
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
      if params[:analysis_type] == 'advanced'
        # 3단계 고급 분석
        service = AdvancedCoverLetterService.new
        result = service.analyze_complete(
          @cover_letter.content,
          @cover_letter.company_name,
          @cover_letter.position
        )
        
        if result[:success]
          @cover_letter.update(analysis_result: result[:full_analysis])
          redirect_to @cover_letter, notice: '3단계 심층 분석이 완료되었습니다.'
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
          redirect_to @cover_letter, notice: '자기소개서 분석이 완료되었습니다.'
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
    redirect_to cover_letters_path, notice: '자기소개서가 삭제되었습니다.'
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
      strengths: extract_section(analysis_text, '강점'),
      improvements: extract_section(analysis_text, '개선'),
      structure: extract_section(analysis_text, '구조'),
      specificity: extract_section(analysis_text, '구체성'),
      job_fit: extract_section(analysis_text, '직무'),
      differentiation: extract_section(analysis_text, '차별화'),
      writing: extract_section(analysis_text, '문장력'),
      suggestions: extract_section(analysis_text, '개선 제안'),
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
      return $1.strip.gsub(/\*/, '')
    elsif analysis_text.match(/회사:\s*([^\n]+)/)
      return $1.strip
    end
    
    nil
  end
  
  def extract_position_from_analysis(analysis_text)
    return nil unless analysis_text
    
    # 직무 추출 패턴
    if analysis_text.match(/모집 직무\*?\*?:\s*([^\n]+)/)
      return $1.strip.gsub(/\*/, '')
    elsif analysis_text.match(/직무:\s*([^\n]+)/)
      return $1.strip
    elsif analysis_text.match(/포지션:\s*([^\n]+)/)
      return $1.strip
    end
    
    nil
  end
  
  def detect_company_size(company_name)
    large_companies = ['삼성', 'Samsung', '현대', 'Hyundai', 'LG', 'SK', '롯데', 'Lotte', 
                      '한화', 'Hanwha', 'GS', '신세계', 'CJ', '두산', 'Doosan', 
                      '포스코', 'POSCO', '카카오', 'Kakao', '네이버', 'Naver', 
                      'KT', 'KB', '신한', '하나', '우리', 'NH농협', '현대차', '기아']
    
    normalized_name = company_name.downcase.gsub(/[\(\)\.주식회사㈜]/, '')
    
    if large_companies.any? { |keyword| normalized_name.include?(keyword.downcase) }
      '대기업'
    elsif company_name.include?('스타트업') || company_name.include?('벤처')
      '스타트업'
    else
      '중견/중소기업'
    end
  end
  
  def perform_basic_company_analysis(company_name)
    # 기본 분석: 간단한 AI 프롬프트로 빠른 분석
    require 'net/http'
    require 'json'
    
    api_key = ENV['OPENAI_API_KEY']
    
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
    
    uri = URI('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{api_key}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      model: ENV['OPENAI_MODEL'] || 'gpt-4.1',
      messages: [
        { role: 'system', content: '당신은 기업 분석 전문가입니다. 요청된 형식에 맞춰 정확하게 응답하세요.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.3,
      max_tokens: 1000
    }.to_json
    
    response = http.request(request)
    result = JSON.parse(response.body)
    
    if result['choices']
      content = result['choices'][0]['message']['content']
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
          recent_issues: { main_topics: ["일반 경영 현황"], summary: "분석 데이터 파싱 실패" },
          business_context: { status: "정상 운영 중", focus_areas: ["제품 개발"] },
          hiring_patterns: { common_positions: ["영업", "생산", "연구개발"], hiring_season: "상시", requirements: "관련 경력 우대" }
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
    return nil unless detect_company_size(company_name) == '대기업'
    
    # 간단한 경쟁사 매핑
    competitor_map = {
      '삼성' => ['LG', 'SK'],
      'LG' => ['삼성', 'SK'],
      '현대' => ['기아', '쌍용'],
      '카카오' => ['네이버', '라인'],
      '네이버' => ['카카오', '구글코리아'],
      'CJ' => ['롯데', '농심'],
      '롯데' => ['CJ', '신세계']
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
end
