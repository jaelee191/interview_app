class Admin::PaymentsController < Admin::BaseController
  def index
    @since = params[:since].presence && Time.zone.parse(params[:since]) || 30.days.ago.beginning_of_day
    @until = params[:until].presence && Time.zone.parse(params[:until]) || Time.current.end_of_day
    scope = PaymentLog.where(created_at: @since..@until)
    @payments = scope.order(created_at: :desc).page(params[:page]).per(20)
    @total_revenue = scope.sum(:amount)
    @last_7d = PaymentLog.where("created_at >= ?", 7.days.ago).sum(:amount)

    respond_to do |format|
      format.html
      format.csv do
        headers["Content-Disposition"] = "attachment; filename=payments-#{@since.to_date}-to-#{@until.to_date}.csv"
        headers["Content-Type"] = "text/csv"
        self.response_body = Enumerator.new do |y|
          y << %w[id user_email order_id amount status created_at].to_csv
          @payments.find_each do |p|
            y << [ p.id, p.user&.email, p.order_id, p.amount, p.status, p.created_at ].to_csv
          end
        end
      end
    end
  end

  def show
    @payment = PaymentLog.find(params[:id])
  end
end
