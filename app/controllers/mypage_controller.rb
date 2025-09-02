class MypageController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @recent_cover_letters = current_user.cover_letters.order(created_at: :desc).limit(5)
    @saved_job_analyses = current_user.job_analyses.order(created_at: :desc).limit(5)
    @saved_company_analyses = current_user.company_analyses.order(created_at: :desc).limit(5)

    @analysis_credits = current_user.analysis_credits
    @free_analyses_used = current_user.free_analyses_used

    # 기존 사용자도 referral_code 보장
    if current_user.referral_code.blank?
      current_user.send(:ensure_referral_code)
      current_user.reload
    end

    # 추천 리워드 1회 지급 처리
    if cookies.encrypted[:ref].present? && !current_user.referral_bonus_claimed
      ref_code = cookies.encrypted[:ref]
      referrer = User.find_by(referral_code: ref_code)
      if referrer && referrer.id != current_user.id
        current_user.increment!(:analysis_credits, 3)
        referrer.increment!(:analysis_credits, 3)
        current_user.update_columns(referrer_id: referrer.id, referral_bonus_claimed: true)
        flash.now[:notice] = "친구 추천 보너스 3건이 지급되었습니다!"
        cookies.delete(:ref)
      end
    end
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
