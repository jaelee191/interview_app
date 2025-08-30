class CoverLetterAnalysisJob < ApplicationJob
  queue_as :default
  
  def perform(cover_letter_id, use_realtime: true)
    cover_letter = CoverLetter.find(cover_letter_id)
    service = AdvancedCoverLetterService.new
    
    Rails.logger.info "Starting analysis job for cover letter #{cover_letter_id}"
    
    # 실시간 진행 상황 표시 여부에 따라 다른 메서드 호출
    if use_realtime
      result = service.analyze_cover_letter_with_progress(
        cover_letter.content,
        cover_letter_id
      )
    else
      # 기존 병렬 처리 (빠르지만 진행 상황 없음)
      result = service.analyze_cover_letter_parallel(cover_letter.content)
    end
    
    # 결과 저장
    if result.present?
      # 분석 결과 저장
      full_analysis = service.format_analysis_result(result)
      
      cover_letter.update!(
        analysis_result: full_analysis,
        analysis_completed_at: Time.current,
        analysis_status: 'completed'
      )
      
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