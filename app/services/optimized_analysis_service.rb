# 최적화된 분석 서비스 - 병렬 처리 + 실시간 피드백
class OptimizedAnalysisService
  def initialize
    @service = AdvancedCoverLetterService.new
  end
  
  def analyze_with_realtime_feedback(content, cover_letter_id)
    Rails.logger.info "Starting optimized analysis for #{cover_letter_id}"
    
    broadcaster = ProgressBroadcaster.new(cover_letter_id)
    results = {}
    completed = []
    mutex = Mutex.new
    
    # 분석 시작 알림
    broadcaster.broadcast_start
    
    # 병렬 처리하되, 각 완료 시마다 즉시 알림
    threads = []
    
    # 첫인상 분석
    threads << Thread.new do
      broadcaster.broadcast_step_start(:first_impression)
      result = @service.analyze_first_impression(content)
      mutex.synchronize do
        results[:first_impression] = result
        completed << :first_impression
        broadcaster.broadcast_step_complete(:first_impression)
        update_overall_progress(broadcaster, completed.size, 5)
      end
    end
    
    # 강점 분석
    threads << Thread.new do
      broadcaster.broadcast_step_start(:strengths)
      result = @service.analyze_strengths(content)
      mutex.synchronize do
        results[:strengths] = result
        completed << :strengths
        broadcaster.broadcast_step_complete(:strengths)
        update_overall_progress(broadcaster, completed.size, 5)
      end
    end
    
    # 개선점 분석
    threads << Thread.new do
      broadcaster.broadcast_step_start(:improvements)
      result = @service.analyze_improvements(content)
      mutex.synchronize do
        results[:improvements] = result
        completed << :improvements
        broadcaster.broadcast_step_complete(:improvements)
        update_overall_progress(broadcaster, completed.size, 5)
      end
    end
    
    # 숨은 보석 발굴
    threads << Thread.new do
      broadcaster.broadcast_step_start(:hidden_gems)
      result = @service.analyze_hidden_gems(content)
      mutex.synchronize do
        results[:hidden_gems] = result
        completed << :hidden_gems
        broadcaster.broadcast_step_complete(:hidden_gems)
        update_overall_progress(broadcaster, completed.size, 5)
      end
    end
    
    # 격려 메시지
    threads << Thread.new do
      broadcaster.broadcast_step_start(:encouragement)
      result = @service.generate_encouragement(content)
      mutex.synchronize do
        results[:encouragement] = result
        completed << :encouragement
        broadcaster.broadcast_step_complete(:encouragement)
        update_overall_progress(broadcaster, completed.size, 5)
      end
    end
    
    # 모든 스레드 완료 대기
    start_time = Time.current
    threads.each(&:join)
    total_time = (Time.current - start_time).to_i
    
    # 최종 결과 조합 및 완료 알림
    final_text = @service.combine_analysis_results(results)
    final_json = @service.combine_analysis_results_to_json(results)
    
    broadcaster.broadcast_complete(final_text)
    
    Rails.logger.info "Analysis completed in #{total_time} seconds"
    
    # 다른 서비스와 동일한 형식으로 반환
    {
      text: final_text,
      json: final_json
    }
  end
  
  private
  
  def update_overall_progress(broadcaster, completed_count, total_count)
    progress_percentage = (completed_count.to_f / total_count * 100).round
    
    # 진행률 업데이트 브로드캐스트
    ActionCable.server.broadcast(
      "analysis_progress_#{broadcaster.instance_variable_get(:@cover_letter_id)}",
      {
        type: 'progress_update',
        progress: progress_percentage,
        completed_steps: completed_count,
        total_steps: total_count,
        message: "#{completed_count}/#{total_count} 단계 완료"
      }
    )
  end
end