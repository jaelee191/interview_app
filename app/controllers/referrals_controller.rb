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
    redirect_to root_path, notice: "추천 링크를 통해 방문하셨습니다."
  end
end
