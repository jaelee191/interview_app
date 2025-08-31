# 하이브리드 분석 서비스 (병렬 + 진행 상황 표시)
class HybridAnalysisService
  def analyze_with_simple_progress(content, cover_letter_id)
    Rails.logger.info "Starting hybrid analysis for cover letter #{cover_letter_id}"
    
    # 간단한 진행 상황만 브로드캐스트
    broadcast_progress(cover_letter_id, 'started', '분석을 시작합니다...')
    
    service = AdvancedCoverLetterService.new
    results = {}
    threads = []
    completed_count = 0
    total_steps = 5
    
    # 병렬 처리로 빠르게 실행
    start_time = Time.current
    
    # 각 분석을 병렬로 실행하되, 완료 시마다 진행률 업데이트
    threads << Thread.new do
      broadcast_progress(cover_letter_id, 'processing', '첫인상 분석 중...', 20)
      results[:first_impression] = service.analyze_first_impression(content)
      completed_count += 1
      broadcast_progress(cover_letter_id, 'processing', "#{completed_count}/#{total_steps} 완료", completed_count * 20)
    end
    
    threads << Thread.new do
      results[:strengths] = service.analyze_strengths(content)
      completed_count += 1
      broadcast_progress(cover_letter_id, 'processing', "#{completed_count}/#{total_steps} 완료", completed_count * 20)
    end
    
    threads << Thread.new do
      results[:improvements] = service.analyze_improvements(content)
      completed_count += 1
      broadcast_progress(cover_letter_id, 'processing', "#{completed_count}/#{total_steps} 완료", completed_count * 20)
    end
    
    threads << Thread.new do
      results[:hidden_gems] = service.analyze_hidden_gems(content)
      completed_count += 1
      broadcast_progress(cover_letter_id, 'processing', "#{completed_count}/#{total_steps} 완료", completed_count * 20)
    end
    
    threads << Thread.new do
      results[:encouragement] = service.generate_encouragement(content)
      completed_count += 1
      broadcast_progress(cover_letter_id, 'processing', "#{completed_count}/#{total_steps} 완료", completed_count * 20)
    end
    
    # 모든 스레드 완료 대기
    threads.each(&:join)
    
    total_time = (Time.current - start_time).to_i
    broadcast_progress(cover_letter_id, 'completed', "분석 완료! (#{total_time}초)", 100)
    
    # 결과 결합
    service.combine_analysis_results(results)
  end
  
  private
  
  def broadcast_progress(cover_letter_id, status, message, progress = nil)
    data = {
      type: status,
      message: message,
      timestamp: Time.current.to_i
    }
    data[:progress] = progress if progress
    data[:redirect_url] = "/cover_letters/#{cover_letter_id}" if status == 'completed'
    
    ActionCable.server.broadcast(
      "analysis_progress_#{cover_letter_id}",
      data
    )
  end
end