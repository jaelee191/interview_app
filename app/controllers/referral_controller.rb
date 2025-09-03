class ReferralController < ApplicationController
  before_action :authenticate_user!, only: [ :create_review ]
  before_action :redirect_if_logged_in, only: [ :landing ]

  def landing
    # 비로그인 사용자를 위한 추천 랜딩 페이지
    @referral_link = ""
    @reviews = ReferralReview.order(created_at: :desc).limit(20)
  end

  def create_review
    ReferralReview.create!(user: current_user, content: params[:content].to_s.first(500))
    redirect_to referral_path, notice: "리뷰가 등록되었습니다. 감사합니다!"
  end
  
  private
  
  def redirect_if_logged_in
    if user_signed_in?
      redirect_to mypage_path, alert: "이미 회원이신 분은 마이페이지에서 추천 링크를 확인하실 수 있습니다."
    end
  end
end
