class MypageController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @user = current_user
    @recent_cover_letters = current_user.cover_letters.order(created_at: :desc).limit(5)
    @saved_job_analyses = current_user.job_analyses.order(created_at: :desc).limit(5)
    @saved_company_analyses = current_user.company_analyses.order(created_at: :desc).limit(5)
  end
  
  def cover_letters
    @cover_letters = current_user.cover_letters.order(created_at: :desc)
  end
  
  def job_analyses
    @job_analyses = current_user.job_analyses.order(created_at: :desc)
  end
  
  def company_analyses
    @company_analyses = current_user.company_analyses.order(created_at: :desc)
  end
end