class CoverLettersController < ApplicationController
  before_action :set_cover_letter, only: [:show, :destroy]
  skip_before_action :verify_authenticity_token, only: [:start_interactive, :send_message, :save_interactive]
  
  def index
    @cover_letters = CoverLetter.order(created_at: :desc)
  end

  def new
    @cover_letter = CoverLetter.new
  end
  
  def interactive
    # 대화형 자소서 작성 페이지
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
end
