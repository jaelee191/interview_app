class Admin::AnalyticsController < Admin::BaseController
  def show
    # 기간별 통계
    @period = params[:period] || "week"
    @date_range = calculate_date_range(@period)

    # 사용자 통계
    @new_users = User.where(created_at: @date_range).count
    @active_users = User.joins(:cover_letters).where(cover_letters: { created_at: @date_range }).distinct.count

    # 자소서 통계
    @total_analyses = CoverLetter.where(created_at: @date_range).count
    @completed_analyses = CoverLetter.where(created_at: @date_range).where.not(analysis_result: nil).count
    @rewritten_letters = CoverLetter.where(created_at: @date_range).where.not(improved_letter: nil).count

    # 일별 차트 데이터
    @daily_data = prepare_daily_data(@date_range)

    # 인기 분석 유형
    @popular_analyses = prepare_popular_analyses(@date_range)
    @popular_max = @popular_analyses.map { |(_, count)| count }.max || 0
  end

  private

  def calculate_date_range(period)
    case period
    when "day"
      1.day.ago..Time.current
    when "week"
      1.week.ago..Time.current
    when "month"
      1.month.ago..Time.current
    else
      1.week.ago..Time.current
    end
  end

  def prepare_daily_data(date_range)
    start_date = date_range.first.to_date
    end_date = date_range.last.to_date

    (start_date..end_date).map do |date|
      {
        date: date.strftime("%m/%d"),
        users: User.where(created_at: date.beginning_of_day..date.end_of_day).count,
        analyses: CoverLetter.where(created_at: date.beginning_of_day..date.end_of_day).count
      }
    end
  end

  def prepare_popular_analyses(date_range)
    CoverLetter.where(created_at: date_range)
               .where.not(company_name: nil)
               .group(:company_name)
               .count
               .sort_by { |_, count| -count }
               .first(10)
  end
end
