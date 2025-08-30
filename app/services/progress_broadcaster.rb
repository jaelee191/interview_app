class ProgressBroadcaster
  attr_reader :cover_letter_id, :total_steps
  
  ANALYSIS_STEPS = {
    first_impression: { 
      name: '첫인상 분석',
      weight: 15,
      message: 'HR 전문가의 시각으로 첫인상을 평가하고 있습니다...'
    },
    strengths: { 
      name: '강점 분석',
      weight: 25,
      message: '자소서의 강점 5가지를 찾아내고 있습니다...'
    },
    improvements: { 
      name: '개선점 분석',
      weight: 25,
      message: '보완이 필요한 부분을 세심하게 검토하고 있습니다...'
    },
    hidden_gems: { 
      name: '숨은 보석 발굴',
      weight: 20,
      message: '놓치고 있던 특별한 강점을 발견하고 있습니다...'
    },
    encouragement: { 
      name: '격려 메시지 작성',
      weight: 15,
      message: '따뜻한 응원의 메시지를 준비하고 있습니다...'
    }
  }.freeze
  
  def initialize(cover_letter_id)
    @cover_letter_id = cover_letter_id
    @total_steps = ANALYSIS_STEPS.size
    @current_step = 0
    @start_time = Time.current
  end
  
  # 분석 시작 알림
  def broadcast_start
    broadcast({
      type: 'analysis_started',
      total_steps: @total_steps,
      steps: ANALYSIS_STEPS.map { |k, v| v[:name] },
      message: '자소서 분석을 시작합니다...',
      estimated_time: 22
    })
  end
  
  # 단계 시작 알림
  def broadcast_step_start(step_key)
    return unless ANALYSIS_STEPS[step_key]
    
    @current_step += 1
    step_info = ANALYSIS_STEPS[step_key]
    
    # 진행률 계산
    progress_percentage = calculate_progress(step_key)
    elapsed_time = (Time.current - @start_time).to_i
    
    broadcast({
      type: 'step_started',
      step: step_key.to_s,
      step_name: step_info[:name],
      step_number: @current_step,
      total_steps: @total_steps,
      progress: progress_percentage,
      message: step_info[:message],
      elapsed_time: elapsed_time,
      estimated_remaining: estimate_remaining_time(progress_percentage, elapsed_time)
    })
  end
  
  # 단계 완료 알림
  def broadcast_step_complete(step_key, result = nil)
    return unless ANALYSIS_STEPS[step_key]
    
    step_info = ANALYSIS_STEPS[step_key]
    
    # 결과 요약 (옵션)
    summary = case step_key
    when :strengths
      "강점 #{result[:items].size}개 발견" if result && result[:items]
    when :improvements
      "개선점 #{result[:items].size}개 도출" if result && result[:items]
    when :hidden_gems
      "숨은 보석 #{result[:items].size}개 발굴" if result && result[:items]
    else
      "완료"
    end
    
    broadcast({
      type: 'step_completed',
      step: step_key.to_s,
      step_name: step_info[:name],
      summary: summary,
      progress: calculate_progress_after(step_key)
    })
  end
  
  # 전체 완료 알림
  def broadcast_complete(analysis_result = nil)
    total_time = (Time.current - @start_time).to_i
    
    broadcast({
      type: 'analysis_completed',
      total_time: total_time,
      progress: 100,
      message: '자소서 분석이 완료되었습니다!',
      redirect_url: analysis_result ? "/cover_letters/#{@cover_letter_id}" : nil
    })
  end
  
  # 에러 발생 알림
  def broadcast_error(error_message)
    broadcast({
      type: 'error',
      message: error_message,
      retry_available: true
    })
  end
  
  # 부분 결과 미리보기 (선택적)
  def broadcast_preview(step_key, preview_data)
    broadcast({
      type: 'preview',
      step: step_key.to_s,
      preview: preview_data
    })
  end
  
  private
  
  def broadcast(data)
    ActionCable.server.broadcast(
      "analysis_progress_#{@cover_letter_id}",
      data.merge(timestamp: Time.current.to_i)
    )
  rescue => e
    Rails.logger.error "Progress broadcast failed: #{e.message}"
  end
  
  def calculate_progress(current_step)
    completed_weight = 0
    in_progress_weight = 0
    
    ANALYSIS_STEPS.each do |key, info|
      if ANALYSIS_STEPS.keys.index(key) < ANALYSIS_STEPS.keys.index(current_step)
        completed_weight += info[:weight]
      elsif key == current_step
        in_progress_weight = info[:weight] / 2  # 현재 진행 중인 단계는 절반
      end
    end
    
    completed_weight + in_progress_weight
  end
  
  def calculate_progress_after(completed_step)
    completed_weight = 0
    
    ANALYSIS_STEPS.each do |key, info|
      if ANALYSIS_STEPS.keys.index(key) <= ANALYSIS_STEPS.keys.index(completed_step)
        completed_weight += info[:weight]
      end
    end
    
    completed_weight
  end
  
  def estimate_remaining_time(progress, elapsed)
    return 0 if progress == 0
    
    total_estimated = (elapsed * 100.0 / progress).to_i
    remaining = total_estimated - elapsed
    [remaining, 0].max
  end
end