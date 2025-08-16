class UserProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_profile
  
  def show
    @career_history = @user_profile.career_history || []
    @projects = @user_profile.projects || []
    @technical_skills = @user_profile.technical_skills || []
    
    # 최근 분석 결과
    @recent_analyses = current_user.cover_letters.order(created_at: :desc).limit(5)
    @ontology_analyses = OntologyAnalysis.joins(:user_profile)
                                         .where(user_profile: @user_profile)
                                         .order(analyzed_at: :desc)
                                         .limit(3)
  end

  def edit
    @career_history = @user_profile.career_history || []
    @projects = @user_profile.projects || []
    @technical_skills = @user_profile.technical_skills || []
  end

  def update
    if @user_profile.update(user_profile_params)
      redirect_to user_profile_path(@user_profile), notice: '프로필이 성공적으로 업데이트되었습니다.'
    else
      render :edit
    end
  end
  
  def add_career
    @user_profile.career_history ||= []
    new_career = {
      id: SecureRandom.uuid,
      company: params[:company],
      position: params[:position],
      duration: params[:duration],
      achievements: params[:achievements]
    }
    @user_profile.career_history << new_career
    
    if @user_profile.save
      render json: { success: true, career: new_career }
    else
      render json: { success: false, errors: @user_profile.errors.full_messages }
    end
  end
  
  def add_project
    @user_profile.projects ||= []
    new_project = {
      id: SecureRandom.uuid,
      name: params[:name],
      role: params[:role],
      duration: params[:duration],
      description: params[:description],
      tech_stack: params[:tech_stack]
    }
    @user_profile.projects << new_project
    
    if @user_profile.save
      render json: { success: true, project: new_project }
    else
      render json: { success: false, errors: @user_profile.errors.full_messages }
    end
  end
  
  def remove_career
    @user_profile.career_history ||= []
    @user_profile.career_history.reject! { |c| c['id'] == params[:career_id] }
    
    if @user_profile.save
      render json: { success: true }
    else
      render json: { success: false }
    end
  end
  
  def remove_project
    @user_profile.projects ||= []
    @user_profile.projects.reject! { |p| p['id'] == params[:project_id] }
    
    if @user_profile.save
      render json: { success: true }
    else
      render json: { success: false }
    end
  end
  
  def update_analysis_preference
    if @user_profile.update(analysis_preference: params[:preference])
      render json: { success: true, preference: params[:preference] }
    else
      render json: { success: false }
    end
  end
  
  def update_inline
    field = params[:field]
    value = params[:value]
    
    # 허용된 필드만 업데이트
    allowed_fields = %w[name email phone education achievements personal_note]
    
    if allowed_fields.include?(field)
      if @user_profile.update(field => value)
        render json: { success: true, value: value }
      else
        render json: { success: false, errors: @user_profile.errors.full_messages }
      end
    else
      render json: { success: false, error: "허용되지 않은 필드입니다" }
    end
  end

  private

  def set_user_profile
    @user_profile = current_user.user_profile || current_user.create_user_profile
  end

  def user_profile_params
    params.require(:user_profile).permit(
      :name, :email, :phone, :education, :achievements, 
      :personal_note, :analysis_preference,
      career_history: [:company, :position, :duration, :achievements],
      projects: [:name, :role, :duration, :description, :tech_stack],
      technical_skills: []
    )
  end
end
