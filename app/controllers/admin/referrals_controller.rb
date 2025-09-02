class Admin::ReferralsController < Admin::BaseController
  def index
    # 클릭/가입/보상 퍼널 통계
    @since = params[:since].presence && Time.zone.parse(params[:since]) || 30.days.ago.beginning_of_day
    @until = params[:until].presence && Time.zone.parse(params[:until]) || Time.current.end_of_day

    clicks = ReferralClick.where(created_at: @since..@until)
    signups = User.where(created_at: @since..@until).where.not(referrer_id: nil)
    rewards = User.where(created_at: @since..@until, referral_bonus_claimed: true)

    @funnel = {
      clicks: clicks.count,
      signups: signups.count,
      rewards: rewards.count,
      signup_rate: (clicks.count.zero? ? 0 : (signups.count.to_f / clicks.count * 100).round(1)),
      reward_rate: (signups.count.zero? ? 0 : (rewards.count.to_f / signups.count * 100).round(1))
    }

    @referred_users = signups.order(created_at: :desc).page(params[:page]).per(20)
    @top_referrers = signups.group(:referrer_id).count.sort_by { |_, c| -c }.first(10)

    respond_to do |format|
      format.html
      format.csv do
        headers["Content-Disposition"] = "attachment; filename=referrals-#{@since.to_date}-to-#{@until.to_date}.csv"
        headers["Content-Type"] = "text/csv"
        self.response_body = Enumerator.new do |y|
          y << %w[user_email referrer_email created_at bonus_claimed].to_csv
          @referred_users.find_each do |u|
            y << [ u.email, User.find_by(id: u.referrer_id)&.email, u.created_at, u.referral_bonus_claimed ].to_csv
          end
        end
      end
    end
  end
end
