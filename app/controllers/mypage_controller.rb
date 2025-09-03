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
    # 신규 가입자는 이미 3건을 받았으므로, 추천인만 3건 추가 지급
    if cookies.encrypted[:ref].present? && !current_user.referral_bonus_claimed
      ref_code = cookies.encrypted[:ref]
      referrer = User.find_by(referral_code: ref_code)
      if referrer && referrer.id != current_user.id
        # 추천인에게만 3건 추가 지급
        referrer.increment!(:analysis_credits, 3)
        # 추천 관계 기록
        current_user.update_columns(referrer_id: referrer.id, referral_bonus_claimed: true)
        flash.now[:notice] = "추천인에게 보너스 3건이 지급되었습니다. 회원님은 이미 무료 3건을 보유하고 계십니다!"
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
