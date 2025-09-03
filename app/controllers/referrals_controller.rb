class ReferralsController < ApplicationController
  # /r/:code → 쿠키에 ref 저장 후 랜딩(홈)으로 이동
  def show
    code = params[:code].to_s.strip
    if code.present?
      cookies.encrypted[:ref] = { value: code, expires: 30.days }
      # 클릭 로깅
      referrer_id = User.find_by(referral_code: code)&.id
      ReferralClick.create!(
        code: code,
        referrer_id: referrer_id,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        landing_path: request.path
      )
    end
    
    # 이미 로그인한 사용자는 추천 링크 사용 불가
    if user_signed_in?
      redirect_to root_path, alert: "이미 로그인된 사용자는 추천 링크를 사용할 수 없습니다."
    else
      # 비로그인 사용자를 추천 전용 랜딩 페이지로 이동
      redirect_to referral_path, notice: "추천 링크를 통해 방문하셨습니다. 회원가입 시 특별 혜택이 제공됩니다!"
    end
  end
end
