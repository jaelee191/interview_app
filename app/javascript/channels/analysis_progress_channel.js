import consumer from "./consumer"

class AnalysisProgressChannel {
  constructor(coverLetterId, callbacks = {}) {
    this.coverLetterId = coverLetterId
    this.callbacks = callbacks
    this.subscription = null
    this.startTime = null
    this.progressTimer = null
  }
  
  connect() {
    this.subscription = consumer.subscriptions.create(
      {
        channel: "AnalysisProgressChannel",
        cover_letter_id: this.coverLetterId
      },
      {
        connected: () => {
          console.log('Connected to analysis progress channel')
          this.onConnected()
        },
        
        disconnected: () => {
          console.log('Disconnected from analysis progress channel')
          this.cleanup()
        },
        
        received: (data) => {
          this.handleMessage(data)
        }
      }
    )
    
    return this
  }
  
  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    this.cleanup()
  }
  
  handleMessage(data) {
    console.log('Received:', data)
    
    switch(data.type) {
      case 'connected':
        this.onConnected()
        break
        
      case 'analysis_started':
        this.onAnalysisStarted(data)
        break
        
      case 'step_started':
        this.onStepStarted(data)
        break
        
      case 'step_completed':
        this.onStepCompleted(data)
        break
        
      case 'preview':
        this.onPreview(data)
        break
        
      case 'analysis_completed':
        this.onAnalysisCompleted(data)
        break
        
      case 'error':
        this.onError(data)
        break
        
      default:
        console.log('Unknown message type:', data.type)
    }
  }
  
  onConnected() {
    if (this.callbacks.onConnected) {
      this.callbacks.onConnected()
    }
  }
  
  onAnalysisStarted(data) {
    this.startTime = Date.now()
    this.startProgressTimer()
    
    if (this.callbacks.onStart) {
      this.callbacks.onStart(data)
    }
    
    // UI 업데이트
    this.updateUI({
      status: 'started',
      message: data.message,
      totalSteps: data.total_steps,
      estimatedTime: data.estimated_time,
      steps: data.steps
    })
  }
  
  onStepStarted(data) {
    if (this.callbacks.onStepStart) {
      this.callbacks.onStepStart(data)
    }
    
    // 진행률 업데이트
    this.updateProgress(data.progress)
    
    // 현재 단계 표시
    this.updateCurrentStep({
      step: data.step,
      stepName: data.step_name,
      stepNumber: data.step_number,
      message: data.message,
      elapsedTime: data.elapsed_time,
      estimatedRemaining: data.estimated_remaining
    })
  }
  
  onStepCompleted(data) {
    if (this.callbacks.onStepComplete) {
      this.callbacks.onStepComplete(data)
    }
    
    // 단계 완료 표시
    this.markStepComplete(data.step, data.summary)
    this.updateProgress(data.progress)
  }
  
  onPreview(data) {
    if (this.callbacks.onPreview) {
      this.callbacks.onPreview(data)
    }
  }
  
  onAnalysisCompleted(data) {
    this.stopProgressTimer()
    
    if (this.callbacks.onComplete) {
      this.callbacks.onComplete(data)
    }
    
    // 완료 UI
    this.updateUI({
      status: 'completed',
      message: data.message,
      totalTime: data.total_time,
      redirectUrl: data.redirect_url
    })
    
    // 자동 리다이렉트 (3초 후)
    if (data.redirect_url) {
      setTimeout(() => {
        window.location.href = data.redirect_url
      }, 3000)
    }
  }
  
  onError(data) {
    this.stopProgressTimer()
    
    if (this.callbacks.onError) {
      this.callbacks.onError(data)
    }
    
    this.updateUI({
      status: 'error',
      message: data.message,
      retryAvailable: data.retry_available
    })
  }
  
  // UI 업데이트 메서드들
  updateUI(options) {
    const container = document.getElementById('analysis-progress-container')
    if (!container) return
    
    switch(options.status) {
      case 'started':
        container.innerHTML = this.renderProgressUI(options)
        break
      case 'completed':
        container.innerHTML = this.renderCompletedUI(options)
        break
      case 'error':
        container.innerHTML = this.renderErrorUI(options)
        break
    }
  }
  
  updateProgress(percentage) {
    const progressBar = document.getElementById('analysis-progress-bar')
    const progressText = document.getElementById('analysis-progress-text')
    
    if (progressBar) {
      progressBar.style.width = `${percentage}%`
      progressBar.setAttribute('aria-valuenow', percentage)
    }
    
    if (progressText) {
      progressText.textContent = `${Math.round(percentage)}%`
    }
  }
  
  updateCurrentStep(stepInfo) {
    const stepName = document.getElementById('current-step-name')
    const stepMessage = document.getElementById('current-step-message')
    const stepNumber = document.getElementById('current-step-number')
    const elapsedTime = document.getElementById('elapsed-time')
    const remainingTime = document.getElementById('remaining-time')
    
    if (stepName) stepName.textContent = stepInfo.stepName
    if (stepMessage) stepMessage.textContent = stepInfo.message
    if (stepNumber) stepNumber.textContent = `${stepInfo.stepNumber}/${this.totalSteps}`
    if (elapsedTime) elapsedTime.textContent = this.formatTime(stepInfo.elapsedTime)
    if (remainingTime) remainingTime.textContent = this.formatTime(stepInfo.estimatedRemaining)
  }
  
  markStepComplete(step, summary) {
    const stepElement = document.querySelector(`[data-step="${step}"]`)
    if (stepElement) {
      stepElement.classList.add('completed')
      const icon = stepElement.querySelector('.step-icon')
      if (icon) {
        icon.innerHTML = '✓'
      }
      if (summary) {
        const summaryElement = stepElement.querySelector('.step-summary')
        if (summaryElement) {
          summaryElement.textContent = summary
        }
      }
    }
  }
  
  // 렌더링 템플릿
  renderProgressUI(options) {
    return `
      <div class="analysis-progress-wrapper">
        <div class="text-center mb-4">
          <h3 class="text-xl font-semibold text-gray-900">자소서 분석 중...</h3>
          <p class="text-gray-600 mt-2">${options.message}</p>
        </div>
        
        <!-- 진행률 바 -->
        <div class="w-full bg-gray-200 rounded-full h-3 mb-4">
          <div id="analysis-progress-bar" 
               class="bg-gradient-to-r from-blue-500 to-emerald-500 h-3 rounded-full transition-all duration-500"
               style="width: 0%"
               role="progressbar" 
               aria-valuenow="0" 
               aria-valuemin="0" 
               aria-valuemax="100">
          </div>
        </div>
        
        <div class="flex justify-between text-sm text-gray-600 mb-6">
          <span>진행률: <span id="analysis-progress-text">0%</span></span>
          <span>경과 시간: <span id="elapsed-time">0:00</span></span>
          <span>예상 남은 시간: <span id="remaining-time">0:22</span></span>
        </div>
        
        <!-- 현재 단계 -->
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <div class="flex items-center">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mr-3"></div>
            <div>
              <p class="font-semibold text-blue-900" id="current-step-name">준비 중...</p>
              <p class="text-sm text-blue-700" id="current-step-message">분석을 시작합니다...</p>
            </div>
          </div>
        </div>
        
        <!-- 단계별 진행 상황 -->
        <div class="space-y-3">
          ${options.steps ? options.steps.map((step, index) => `
            <div data-step="${step.toLowerCase().replace(/\s+/g, '_')}" 
                 class="step-item flex items-center p-3 bg-white rounded-lg border border-gray-200">
              <div class="step-icon w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center text-gray-500 mr-3">
                ${index + 1}
              </div>
              <div class="flex-1">
                <p class="font-medium text-gray-900">${step}</p>
                <p class="step-summary text-sm text-gray-500"></p>
              </div>
            </div>
          `).join('') : ''}
        </div>
      </div>
    `
  }
  
  renderCompletedUI(options) {
    return `
      <div class="text-center py-8">
        <div class="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-10 h-10 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
        </div>
        <h3 class="text-2xl font-bold text-gray-900 mb-2">분석 완료!</h3>
        <p class="text-gray-600 mb-4">${options.message}</p>
        <p class="text-sm text-gray-500">총 소요 시간: ${this.formatTime(options.totalTime)}</p>
        ${options.redirectUrl ? `
          <p class="text-sm text-blue-600 mt-4">잠시 후 결과 페이지로 이동합니다...</p>
        ` : ''}
      </div>
    `
  }
  
  renderErrorUI(options) {
    return `
      <div class="text-center py-8">
        <div class="w-20 h-20 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-10 h-10 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </div>
        <h3 class="text-xl font-bold text-gray-900 mb-2">분석 중 오류 발생</h3>
        <p class="text-gray-600 mb-4">${options.message}</p>
        ${options.retryAvailable ? `
          <button onclick="location.reload()" 
                  class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
            다시 시도
          </button>
        ` : ''}
      </div>
    `
  }
  
  // 유틸리티
  formatTime(seconds) {
    if (!seconds) return '0:00'
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }
  
  startProgressTimer() {
    this.progressTimer = setInterval(() => {
      const elapsed = Math.floor((Date.now() - this.startTime) / 1000)
      const elapsedElement = document.getElementById('elapsed-time')
      if (elapsedElement) {
        elapsedElement.textContent = this.formatTime(elapsed)
      }
    }, 1000)
  }
  
  stopProgressTimer() {
    if (this.progressTimer) {
      clearInterval(this.progressTimer)
      this.progressTimer = null
    }
  }
  
  cleanup() {
    this.stopProgressTimer()
  }
}

// Export for use in other files
window.AnalysisProgressChannel = AnalysisProgressChannel
export default AnalysisProgressChannel