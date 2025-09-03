class ReferralController < ApplicationController
  before_action :authenticate_user!, only: [ :create_review, :index ]
  before_action :redirect_if_logged_in, only: [ :landing ]

  def landing
    # 비로그인 사용자를 위한 추천 랜딩 페이지
    @referral_link = ""
    @reviews = ReferralReview.order(created_at: :desc).limit(20)
  end

  # 로그인한 사용자를 위한 친구 추천 페이지
  def index
    @user = current_user
    # 기존 사용자도 referral_code 보장
    if @user.referral_code.blank?
      @user.send(:ensure_referral_code)
      @user.reload
    end
    
    @referral_url = referral_redirect_url(code: @user.referral_code)
    @referred_count = User.where(referrer_id: @user.id).count
    @total_earned = @referred_count * 3
    @recent_referrals = User.where(referrer_id: @user.id).order(created_at: :desc).limit(5)
    @reviews = ReferralReview.order(created_at: :desc).limit(10)
  end

  def create_review
    ReferralReview.create!(user: current_user, content: params[:content].to_s.first(500))
    redirect_to referral_path, notice: "리뷰가 등록되었습니다. 감사합니다!"
  end
  
  private
  
  def redirect_if_logged_in
    if user_signed_in?
      redirect_to referral_index_path
    end
  end
end
