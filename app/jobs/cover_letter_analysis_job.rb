class CoverLetterAnalysisJob < ApplicationJob
  queue_as :default
  
  # 타임아웃 설정 (3분)
  retry_on Timeout::Error, wait: 5.seconds, attempts: 2
  
  def perform(cover_letter_id, use_realtime: false)  # 기본값을 false로 변경
    cover_letter = CoverLetter.find(cover_letter_id)
    
    Rails.logger.info "Starting analysis job for cover letter #{cover_letter_id}"
    
    # 실시간 진행 상황 표시 여부에 따라 다른 메서드 호출
    if use_realtime
      # 최적화된 병렬 처리 + 실시간 피드백 (빠르고 진행 상황도 표시)
      optimized_service = OptimizedAnalysisService.new
      result = optimized_service.analyze_with_realtime_feedback(
        cover_letter.content,
        cover_letter_id
      )
    else
      # 기존 병렬 처리 (빠르지만 진행 상황 없음)
      service = AdvancedCoverLetterService.new
      
      # 간단한 진행 알림만 추가
      ActionCable.server.broadcast(
        "analysis_progress_#{cover_letter_id}",
        { type: 'analysis_started', message: '고속 분석 모드로 처리 중...' }
      )
      
      result = service.analyze_cover_letter_parallel(cover_letter.content)
      
      ActionCable.server.broadcast(
        "analysis_progress_#{cover_letter_id}", 
        { type: 'analysis_completed', redirect_url: "/cover_letters/#{cover_letter_id}" }
      )
    end
    
    # 결과 저장
    if result.present?
      # 새로운 형식: text와 json 구조를 모두 포함
      if result.is_a?(Hash) && result[:text] && result[:json]
        cover_letter.update!(
          advanced_analysis: result[:text],
          advanced_analysis_json: result[:json],
          analysis_completed_at: Time.current,
          analysis_status: 'completed'
        )
      else
        # 구형식 호환성 유지
        full_analysis = result.is_a?(String) ? result : result.to_json
        cover_letter.update!(
          advanced_analysis: full_analysis,
          analysis_completed_at: Time.current,
          analysis_status: 'completed'
        )
      end
      
      # 완료 알림 (이미 broadcaster에서 처리했지만 백업)
      ActionCable.server.broadcast(
        "analysis_progress_#{cover_letter_id}",
        {
          type: 'save_completed',
          redirect_url: "/cover_letters/#{cover_letter_id}",
          message: '분석이 완료되어 저장되었습니다!'
        }
      )
    else
      cover_letter.update!(
        analysis_status: 'failed',
        analysis_error: '분석 중 오류가 발생했습니다'
      )
      
      ActionCable.server.broadcast(
        "analysis_progress_#{cover_letter_id}",
        {
          type: 'error',
          message: '분석 중 오류가 발생했습니다. 다시 시도해주세요.'
        }
      )
    end
    
  rescue => e
    Rails.logger.error "Analysis job failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # 에러 상태 업데이트
    cover_letter&.update(
      analysis_status: 'failed',
      analysis_error: e.message
    )
    
    # 에러 브로드캐스트
    ActionCable.server.broadcast(
      "analysis_progress_#{cover_letter_id}",
      {
        type: 'error',
        message: "분석 실패: #{e.message}",
        retry_available: true
      }
    )
    
    raise # 재시도를 위해 예외 다시 발생
  end
end