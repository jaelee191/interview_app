class PricingController < ApplicationController
  before_action :authenticate_user!, only: [ :purchase_pack, :confirm, :success, :fail ]

  def index
  end

  # 결제 수단 선택형 체크아웃 (테스트 UI)
  def checkout
    @amount = (params[:amount] || 20000).to_i
    @order_id = "UI-#{SecureRandom.hex(6)}"
  end

  # 무료 3건 소진 시 업셀 페이지
  def upgrade
    @analysis_credits = current_user&.analysis_credits.to_i
    @free_used        = current_user&.free_analyses_used.to_i
  end

  # 토스페이먼츠 결제 시작 (10건 패키지)
  def purchase_pack
    amount = 20000
    order_id = "PK10-#{SecureRandom.hex(8)}"
    order_name = "자소서 분석 10건 패키지"

    # 결제 준비 정보 전달 (프론트에서 tosspayments SDK로 결제 요청)
    render json: {
      success: true,
      orderId: order_id,
      orderName: order_name,
      amount: amount,
      customerEmail: current_user.email,
      customerName: current_user.user_profile&.name || current_user.email.split("@").first
    }
  end

  # 결제 승인 콜백 (서버 검증)
  def confirm
    payment_key = params[:paymentKey]
    order_id    = params[:orderId]
    amount      = params[:amount].to_i

    Rails.logger.info "[TossPayments] Confirm request - paymentKey: #{payment_key}, orderId: #{order_id}, amount: #{amount}"

    unless payment_key && order_id && amount == 20000
      Rails.logger.error "[TossPayments] Invalid payment info - amount: #{amount}"
      render json: { success: false, error: "유효하지 않은 결제 정보" }, status: 422 and return
    end

    # 토스 승인 요청
    begin
      secret_key = ENV["TOSS_SECRET_KEY"].presence || Rails.application.credentials.dig(:toss, :secret_key)
      
      unless secret_key
        Rails.logger.error "[TossPayments] Secret key not found"
        render json: { success: false, error: "결제 설정 오류" }, status: 500 and return
      end
      
      # 시크릿 키 뒤에 콜론(:) 추가 후 base64 인코딩
      auth_header = "Basic #{Base64.strict_encode64("#{secret_key}:")}"
      
      uri = URI("https://api.tosspayments.com/v1/payments/confirm")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = auth_header
      req["Content-Type"] = "application/json"
      
      request_body = { 
        paymentKey: payment_key, 
        orderId: order_id, 
        amount: amount 
      }
      
      req.body = request_body.to_json
      
      Rails.logger.info "[TossPayments] Sending confirm request to Toss API"
      Rails.logger.debug "[TossPayments] Request body: #{request_body.to_json}"
      
      res = http.request(req)
      
      Rails.logger.info "[TossPayments] Response code: #{res.code}"
      Rails.logger.info "[TossPayments] Response body: #{res.body}"
      
      if res.code.to_i.between?(200, 299)
        # 결제 성공 → 10건 적립
        current_user.increment!(:analysis_credits, 10)
        
        # 결제 로그 저장
        PaymentLog.create!(
          user: current_user,
          order_id: order_id,
          payment_key: payment_key,
          amount: amount,
          status: "DONE"
        )
        
        Rails.logger.info "[TossPayments] Payment confirmed successfully for user #{current_user.id}"
        render json: { success: true, credits: current_user.analysis_credits }
      else
        error_data = JSON.parse(res.body) rescue { "message" => res.body }
        error_code = error_data["code"] || "UNKNOWN"
        error_message = error_data["message"] || "결제 승인에 실패했습니다"
        
        Rails.logger.error "[TossPayments] Confirm failed - Code: #{error_code}, Message: #{error_message}"
        render json: { success: false, error: error_message, code: error_code }, status: 422
      end
    rescue => e
      Rails.logger.error "[TossPayments] Confirm error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { success: false, error: "결제 처리 중 오류가 발생했습니다" }, status: 500
    end
  end

  # 결제 성공 페이지 (토스 successUrl에서 리다이렉트)
  # GET /pricing/success?paymentKey=...&orderId=...&amount=...
  def success
    payment_key = params[:paymentKey]
    order_id    = params[:orderId]
    amount      = params[:amount].to_i

    # 서버 승인 → 크레딧 적립 후 마이페이지로 이동
    confirm_res = request_approval(payment_key, order_id, amount)
    if confirm_res[:ok]
      current_user.increment!(:analysis_credits, 10)
      PaymentLog.create!(user: current_user, order_id: order_id, payment_key: payment_key, amount: amount, status: "DONE")
      redirect_to mypage_path, notice: "결제가 완료되었습니다. 현재 잔여 건수: #{current_user.analysis_credits}건"
    else
      redirect_to pricing_path, alert: "결제 승인 실패: #{confirm_res[:error] || '알 수 없는 오류'}"
    end
  end

  # 결제 실패 페이지 (토스 failUrl에서 리다이렉트)
  def fail
    message = params[:message] || "\uACB0\uC81C\uAC00 \uCDE8\uC18C\uB418\uC5C8\uAC70\uB098 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4."
    redirect_to pricing_path, alert: message
  end

  # 개발용 모의 승인 (clientKey 미설정 시 임시 사용)
  def mock_success
    current_user.increment!(:analysis_credits, 10)
    render json: { success: true, credits: current_user.analysis_credits }
  end

  private

  def request_approval(payment_key, order_id, amount)
    return { ok: false, error: "\uC798\uBABB\uB41C \uC694\uCCAD" } unless payment_key && order_id && amount == 20000
    
    secret_key = ENV["TOSS_SECRET_KEY"].presence || Rails.application.credentials.dig(:toss, :secret_key)
    return { ok: false, error: "\uACB0\uC81C \uC124\uC815 \uC624\uB958" } unless secret_key
    
    uri = URI("https://api.tosspayments.com/v1/payments/confirm")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    req = Net::HTTP::Post.new(uri)
    # 시크릿 키 뒤에 콜론(:) 추가 후 base64 인코딩
    req["Authorization"] = "Basic #{Base64.strict_encode64("#{secret_key}:")}"
    req["Content-Type"]  = "application/json"
    req.body = { paymentKey: payment_key, orderId: order_id, amount: amount }.to_json
    
    Rails.logger.info "[TossPayments] Sending approval request"
    res = http.request(req)
    
    if res.code.to_i.between?(200, 299)
      { ok: true }
    else
      error_data = JSON.parse(res.body) rescue { "message" => res.body }
      Rails.logger.error "[TossPayments] Approval failed: #{res.code} #{res.body}"
      { ok: false, error: error_data["message"] || res.body }
    end
  rescue => e
    Rails.logger.error "[TossPayments] Approval error: #{e.message}"
    { ok: false, error: e.message }
  end
end
