class AnalysisProgressChannel < ApplicationCable::Channel
  def subscribed
    if params[:cover_letter_id].present?
      stream_from "analysis_progress_#{params[:cover_letter_id]}"
      
      # 연결 성공 메시지
      ActionCable.server.broadcast(
        "analysis_progress_#{params[:cover_letter_id]}",
        {
          type: 'connected',
          message: '실시간 분석 시작 준비 완료'
        }
      )
    else
      reject
    end
  end

  def unsubscribed
    # 정리 작업
  end
  
  # 클라이언트에서 진행 상황 요청
  def request_status(data)
    cover_letter_id = data['cover_letter_id']
    
    # 현재 상태 전송
    ActionCable.server.broadcast(
      "analysis_progress_#{cover_letter_id}",
      {
        type: 'status_update',
        status: 'ready'
      }
    )
  end
end