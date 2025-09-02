class Admin::DashboardController < Admin::BaseController
  def index
    # 주요 통계
    @total_users = User.count
    @total_cover_letters = CoverLetter.count
    @today_users = User.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day).count
    @this_week_cover_letters = CoverLetter.where(created_at: 1.week.ago..Time.current).count
    
    # 최근 활동
    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_cover_letters = CoverLetter.includes(:user).order(created_at: :desc).limit(5)
    
    # 차트 데이터
    @daily_stats = prepare_daily_stats
    @analysis_distribution = prepare_analysis_distribution
  end

  private

  def prepare_daily_stats
    (6.days.ago.to_date..Date.current).map do |date|
      {
        date: date.strftime("%m/%d"),
        users: User.where(created_at: date.beginning_of_day..date.end_of_day).count,
        analyses: CoverLetter.where(created_at: date.beginning_of_day..date.end_of_day).count
      }
    end
  end

  def prepare_analysis_distribution
    total = CoverLetter.count
    return {} if total == 0

    {
      "미분석" => CoverLetter.where(analysis_result: nil).count,
      "분석 완료" => CoverLetter.where.not(analysis_result: nil).where(improved_letter: nil).count,
      "리라이트 완료" => CoverLetter.where.not(improved_letter: nil).count
    }
  end
end