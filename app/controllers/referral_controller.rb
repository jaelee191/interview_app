class ReferralController < ApplicationController
  before_action :authenticate_user!, only: [ :create_review ]

  def landing
    @referral_link = current_user ? referral_redirect_url(code: current_user.referral_code) : referral_redirect_url(code: "")
    @reviews = ReferralReview.order(created_at: :desc).limit(20)
  end

  def create_review
    ReferralReview.create!(user: current_user, content: params[:content].to_s.first(500))
    redirect_to referral_path, notice: "리뷰가 등록되었습니다. 감사합니다!"
  end
end
