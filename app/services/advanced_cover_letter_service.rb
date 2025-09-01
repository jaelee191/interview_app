require "net/http"
require "json"
require "open3"

class AdvancedCoverLetterService
  OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
  PROMPTS_FILE = Rails.root.join('config', 'prompts', 'cover_letter_analysis_prompts.yml')

  def initialize
    @api_key = ENV["OPENAI_API_KEY"]
    @model = ENV["OPENAI_MODEL"] || "gpt-4.1"
    load_prompts
  end

  private

  def load_prompts
    @prompts = YAML.load_file(PROMPTS_FILE)
    @prompts.deep_symbolize_keys!
  rescue => e
    Rails.logger.error "프롬프트 파일 로드 실패: #{e.message}"
    @prompts = {}
  end

  def get_prompt(key, variables = {})
    prompt_data = @prompts.dig(:analysis_prompts, key)
    return nil unless prompt_data

    prompt = prompt_data[:prompt]
    variables.each do |var_key, var_value|
      prompt = prompt.gsub("{{#{var_key}}}", var_value.to_s)
    end
    
    { prompt: prompt, max_tokens: prompt_data[:max_tokens] || 3000 }
  end

  public

  # PUBLIC 메서드: 실시간 진행 상황과 함께 하이브리드 분석 (병렬+순차)
  def analyze_cover_letter_with_progress(content, cover_letter_id)
    Rails.logger.info "=== 실시간 진행 상황 분석 시작 ==="

    broadcaster = ProgressBroadcaster.new(cover_letter_id)
    results = {}
    errors = []

    begin
      # 분석 시작 알림
      broadcaster.broadcast_start

      # 1. 첫인상 분석
      broadcaster.broadcast_step_start(:first_impression)
      results[:first_impression] = analyze_first_impression(content)
      broadcaster.broadcast_step_complete(:first_impression)

      # 2. 강점 분석
      broadcaster.broadcast_step_start(:strengths)
      results[:strengths] = analyze_strengths(content)
      broadcaster.broadcast_step_complete(:strengths,
        { items: results[:strengths].scan(/\*\*강점/).size }
      )

      # 3. 개선점 분석
      broadcaster.broadcast_step_start(:improvements)
      results[:improvements] = analyze_improvements(content)
      broadcaster.broadcast_step_complete(:improvements,
        { items: results[:improvements].scan(/\*\*개선/).size }
      )

      # 4. 숨은 보석 발굴
      broadcaster.broadcast_step_start(:hidden_gems)
      results[:hidden_gems] = analyze_hidden_gems(content)
      broadcaster.broadcast_step_complete(:hidden_gems,
        { items: 3 }
      )

      # 5. 격려 메시지
      broadcaster.broadcast_step_start(:encouragement)
      results[:encouragement] = generate_encouragement(content)
      broadcaster.broadcast_step_complete(:encouragement)

      # 분석 완료 - JSON 구조로 생성
      json_result = combine_analysis_results_to_json(results)
      text_result = combine_analysis_results(results)

      broadcaster.broadcast_complete(text_result)

      {
        text: text_result,
        json: json_result
      }

    rescue => e
      Rails.logger.error "Analysis with progress failed: #{e.message}"
      broadcaster.broadcast_error("분석 중 오류가 발생했습니다: #{e.message}")
      raise
    end
  end

  # Python NLP 분석 수행
  def analyze_with_python(content, company_name = nil, position = nil)
    script_path = Rails.root.join("python_analysis", "advanced_analyzer.py")

    input_data = {
      text: content,
      company: company_name,
      position: position
    }.to_json

    stdout, stderr, status = Open3.capture3(
      "python3", script_path.to_s,
      stdin_data: input_data
    )

    if status.success?
      begin
        JSON.parse(stdout)
      rescue JSON::ParserError => e
        Rails.logger.error "Python 분석 결과 파싱 오류: #{e.message}"
        { error: "분석 결과 처리 오류" }
      end
    else
      Rails.logger.error "Python 분석 실행 오류: #{stderr}"
      { error: "Python 분석 실행 실패" }
    end
  rescue StandardError => e
    Rails.logger.error "Python 분석 오류: #{e.message}"
    { error: "분석 시스템 오류" }
  end

  # 자소서 분석만 수행 (기업 분석 제외)
  def analyze_cover_letter_only(content)
    return { error: "API 키가 설정되지 않았습니다" } unless @api_key

    # 2단계 자기소개서 분석만 실행
    cover_letter_analysis = analyze_cover_letter(content)

    {
      success: true,
      analysis: cover_letter_analysis,
      full_analysis: format_cover_letter_analysis(cover_letter_analysis)
    }
  rescue StandardError => e
    Rails.logger.error "자소서 분석 오류: #{e.message}"
    { error: "분석 중 오류가 발생했습니다: #{e.message}" }
  end

  # Python 품질 향상을 포함한 리라이트
  def rewrite_with_python_enhancement(content, feedback_analysis, company_name = nil, position = nil, rewrite_mode = "preserve")
    Rails.logger.info "=== 최적화된 리라이트 시작 (GPT → Python 후처리) ==="
    Rails.logger.info "리라이트 모드: #{rewrite_mode}"

    # 1단계: GPT로 고품질 리라이트 생성 (rewrite_mode 전달)
    basic_result = rewrite_with_feedback_only(content, feedback_analysis, company_name, position, rewrite_mode)

    unless basic_result[:success]
      return basic_result
    end

    # 2단계: Python으로 품질 분석 및 미세 조정
    python_service = PythonAnalysisService.new

    # 분석만 수행 (텍스트 보존)
    analysis_result = python_service.analyze_text_quality(
      basic_result[:rewritten_letter],
      company_name
    )

    # 3단계: Python 분석 기반 선택적 향상
    if analysis_result[:success]
      enhanced_text = basic_result[:rewritten_letter]

      # AI 패턴만 제거 (구조는 유지)
      if analysis_result[:data]["ai_patterns_detected"] && analysis_result[:data]["ai_patterns_detected"] > 0
        enhanced_text = python_service.remove_ai_patterns_only(enhanced_text)[:data]["text"] rescue enhanced_text
      end

      # 메트릭스와 함께 반환
      {
        success: true,
        rewritten_letter: enhanced_text,
        original_rewrite: basic_result[:rewritten_letter],
        metrics: analysis_result[:data]["improvements"],
        before_metrics: analysis_result[:data]["before_metrics"],
        after_metrics: analysis_result[:data]["after_metrics"],
        suggestions: analysis_result[:data]["suggestions"],
        optimization_type: "hybrid_gpt_python"
      }
    else
      # Python 분석 실패시에도 GPT 결과는 보존
      Rails.logger.warn "Python 분석 실패, GPT 리라이트만 사용: #{analysis_result[:error]}"
      basic_result.merge(optimization_type: "gpt_only")
    end
  rescue => e
    Rails.logger.error "최적화 오류: #{e.message}"
    basic_result || { success: false, error: e.message }
  end

  # 피드백 기반 자소서 리라이트 (기업 분석 제외)
  def rewrite_with_feedback_only(content, feedback_analysis, company_name = nil, position = nil, rewrite_mode = "preserve")
    return { error: "API 키가 설정되지 않았습니다" } unless @api_key

    # 3단계: 피드백 기반 맞춤형 자기소개서 생성
    rewritten_letter = generate_improved_letter(
      content,
      feedback_analysis,
      company_name,
      position,
      rewrite_mode
    )

    {
      success: true,
      rewritten_letter: rewritten_letter
    }
  rescue StandardError => e
    Rails.logger.error "리라이트 오류: #{e.message}"
    { error: "리라이트 중 오류가 발생했습니다: #{e.message}" }
  end

  # 기존 메서드 (하위 호환성 유지)
  def analyze_complete(content, company_name, position)
    return { error: "API 키가 설정되지 않았습니다" } unless @api_key

    # Python NLP 분석 수행
    python_analysis = analyze_with_python(content, company_name, position)

    # 1단계: 기업 분석 (선택적 - 현재는 스킵)
    # company_analysis = analyze_company(company_name)

    # 2단계: 자기소개서 분석
    cover_letter_analysis = analyze_cover_letter(content)

    # 3단계: 피드백 기반 맞춤형 자기소개서 생성
    customized_letter = generate_improved_letter(
      content,
      cover_letter_analysis,
      company_name,
      position
    )

    {
      success: true,
      cover_letter_analysis: cover_letter_analysis,
      customized_letter: customized_letter,
      python_analysis: python_analysis,
      full_analysis: format_full_analysis_simple(cover_letter_analysis, customized_letter)
    }
  rescue StandardError => e
    Rails.logger.error "고급 분석 오류: #{e.message}"
    { error: "분석 중 오류가 발생했습니다: #{e.message}" }
  end

  # 개별 분석 메서드들 (OptimizedAnalysisService에서 사용)
  def analyze_first_impression(content)
    return [] unless content.present?

    # 숫자. 형식의 항목 찾기 (예: "1. 지원 동기", "2. 성장 과정")
    sections = content.scan(/^\d+\.\s*([^\n]+)/).flatten

    # 정리 및 정규화
    sections.map do |section|
      section.strip.gsub(/\[.*?\]/, "").strip # 대괄호 안의 부제목 제거
    end.reject(&:empty?)
  end

  def analyze_company(company_name)
    prompt = <<~PROMPT
      당신은 기업 분석 전문가입니다. #{company_name}에 대해 다음을 분석해주세요:

      **분석 항목:**
      1. 기업의 핵심 사업 분야와 비전
      2. 최근 1년간 주요 이슈 및 현안 (경영진 발언, 신사업, 위기상황 등)
      3. 업계 내 포지션과 경쟁우위
      4. 기업이 추구하는 인재상과 핵심 역량
      5. 조직문화와 가치관

      **출력 형식:**
      ## 🏢 #{company_name} 분석 리포트
      **핵심 사업:** [간단 설명]
      **최근 현안:** [3-5개 주요 이슈]
      **인재상:** [원하는 인재 유형]
      **키워드:** [핵심 키워드 5개]

      한국 기업의 최신 정보를 바탕으로 구체적으로 분석해주세요.
    PROMPT

    response = make_api_request(prompt, "기업 분석 전문가")
    parse_response(response)[:content]
  end

  # 병렬처리를 위한 개별 섹션 분석 메서드들
  def analyze_first_impression(content, user_name = nil)
    prompt_data = get_prompt(:first_impression, {
      user_name: user_name || "지원자",
      content: content
    })
    
    unless prompt_data
      Rails.logger.error "첫인상 분석 프롬프트를 찾을 수 없습니다"
      return "프롬프트 로드 실패"
    end

    # max_tokens를 더 크게 설정
    actual_max_tokens = [prompt_data[:max_tokens] || 4000, 8000].max
    Rails.logger.info "첫인상 분석 max_tokens: #{actual_max_tokens}"
    response = make_api_request(prompt_data[:prompt], "HR 15년차 선배", actual_max_tokens)
    parse_response(response)[:content]
  end

  def analyze_strengths(content)
    prompt_data = get_prompt(:strengths, {
      content: content
    })
    
    unless prompt_data
      Rails.logger.error "강점 분석 프롬프트를 찾을 수 없습니다"
      return "프롬프트 로드 실패"
    end

    # max_tokens를 더 크게 설정
    actual_max_tokens = [prompt_data[:max_tokens] || 5000, 10000].max
    Rails.logger.info "강점 분석 max_tokens: #{actual_max_tokens}"
    response = make_api_request(prompt_data[:prompt], "강점 분석 전문가", actual_max_tokens)
    parse_response(response)[:content]
  end

  def analyze_improvements(content)
    prompt_data = get_prompt(:improvements, {
      content: content
    })
    
    unless prompt_data
      Rails.logger.error "개선점 분석 프롬프트를 찾을 수 없습니다"
      return "프롬프트 로드 실패"
    end

    # max_tokens를 더 크게 설정
    actual_max_tokens = [prompt_data[:max_tokens] || 5000, 10000].max
    Rails.logger.info "개선점 분석 max_tokens: #{actual_max_tokens}"
    response = make_api_request(prompt_data[:prompt], "개선점 분석 전문가", actual_max_tokens)
    parse_response(response)[:content]
  end

  def analyze_hidden_gems(content)
    prompt_data = get_prompt(:hidden_gems, {
      content: content
    })
    
    unless prompt_data
      Rails.logger.error "숨은 보석 분석 프롬프트를 찾을 수 없습니다"
      return "프롬프트 로드 실패"
    end

    # max_tokens를 더 크게 설정
    actual_max_tokens = [prompt_data[:max_tokens] || 3000, 6000].max
    Rails.logger.info "숨은 보석 분석 max_tokens: #{actual_max_tokens}"
    response = make_api_request(prompt_data[:prompt], "잠재력 발굴 전문가", actual_max_tokens)
    parse_response(response)[:content]
  end

  def generate_encouragement(content)
    prompt_data = get_prompt(:encouragement, {
      content: content
    })
    
    unless prompt_data
      Rails.logger.error "격려 메시지 프롬프트를 찾을 수 없습니다"
      return "프롬프트 로드 실패"
    end

    # max_tokens를 더 크게 설정
    actual_max_tokens = [prompt_data[:max_tokens] || 2000, 4000].max
    Rails.logger.info "격려 메시지 max_tokens: #{actual_max_tokens}"
    response = make_api_request(prompt_data[:prompt], "HR 멘토", actual_max_tokens)
    parse_response(response)[:content]
  end

  # [삭제됨 - 위로 이동함]

  # 병렬처리로 자소서 분석 실행 (기존 메서드)
  def analyze_cover_letter_parallel(content)
    results = {}
    threads = []
    errors = []

    # 각 섹션을 병렬로 분석
    threads << Thread.new do
      begin
        results[:first_impression] = analyze_first_impression(content)
      rescue => e
        errors << "첫인상 분석 실패: #{e.message}"
      end
    end

    threads << Thread.new do
      begin
        results[:strengths] = analyze_strengths(content)
      rescue => e
        errors << "강점 분석 실패: #{e.message}"
      end
    end

    threads << Thread.new do
      begin
        results[:improvements] = analyze_improvements(content)
      rescue => e
        errors << "개선점 분석 실패: #{e.message}"
      end
    end

    threads << Thread.new do
      begin
        results[:hidden_gems] = analyze_hidden_gems(content)
      rescue => e
        errors << "숨은 보석 분석 실패: #{e.message}"
      end
    end

    threads << Thread.new do
      begin
        results[:encouragement] = generate_encouragement(content)
      rescue => e
        errors << "격려 메시지 생성 실패: #{e.message}"
      end
    end

    # 모든 스레드 완료 대기
    threads.each(&:join)

    # 에러 확인
    unless errors.empty?
      Rails.logger.error "병렬 분석 중 오류 발생: #{errors.join(', ')}"
      # 일부 실패해도 성공한 부분은 반환
    end

    # 결과 조합 - JSON과 텍스트 모두 반환
    {
      text: combine_analysis_results(results),
      json: combine_analysis_results_to_json(results)
    }
  end

  # JSON 구조로 분석 결과 변환
  def combine_analysis_results_to_json(results)
    {
      sections: [
        {
          number: 1,
          title: "첫인상 & 전체적인 느낌",
          content: results[:first_impression] || "분석 중 오류가 발생했습니다.",
          items: []
        },
        {
          number: 2,
          title: "잘 쓴 부분 (Top 5 강점)",
          content: "",
          items: parse_numbered_items(results[:strengths])
        },
        {
          number: 3,
          title: "아쉬운 부분 (Top 5 개선점)",
          content: "",
          items: parse_numbered_items(results[:improvements])
        },
        {
          number: 4,
          title: "놓치고 있는 숨은 보석들",
          content: "",
          items: parse_numbered_items(results[:hidden_gems])
        },
        {
          number: 5,
          title: "격려와 응원 메시지",
          content: results[:encouragement] || "분석 중 오류가 발생했습니다.",
          items: []
        }
      ],
      analyzed_at: Time.current
    }
  end

  # 텍스트에서 번호 항목 파싱 (새로운 통일된 출력 형식에 맞춤)
  def parse_numbered_items(text)
    return [] if text.blank?

    # 통일된 출력 형식: ### 1. **[제목]**
    # 패턴 설명:
    # - ### 숫자. **제목** 형식 매칭
    # - 내용은 다음 ### 또는 --- 구분선 또는 문서 끝까지 모두 캡처
    # - [\s\S]*? 사용으로 줄바꿈 포함 모든 문자 캡처 (non-greedy)
    section_pattern = /###\s*(\d+)\.\s*\*\*([^*]+)\*\*\s*\n([\s\S]*?)(?=\n###\s*\d+\.\s*\*\*|\n---|\z)/m
    matches = text.scan(section_pattern)

    if matches.any?
      items = []
      matches.each do |match|
        number, title, content = match

        # 제목 정리 (대괄호가 없는 경우)
        clean_title = title.strip

        # 내용에서 불필요한 안내 텍스트 제거
        # 주의: [1문단], [2문단] 등의 구조 표시는 유지하되, 빈 대괄호만 제거
        clean_content = content.strip
        # 빈 대괄호나 의미없는 대괄호만 제거 (예: [동일한 구조로 작성])
        clean_content = clean_content.gsub(/\[동일한 구조로 작성\]/m, "")
        clean_content = clean_content.gsub(/\[\s*\]/m, "").strip

        items << {
          number: number.to_i,
          title: clean_title,
          content: clean_content
        }
      end

      Rails.logger.info "파싱 성공: #{items.length}개 항목 발견"
      items
    else
      Rails.logger.warn "새로운 패턴으로 파싱 실패, 기존 패턴 시도: #{text[0..200]}..."

      # 기존 패턴들도 시도 (하위 호환성)
      # 패턴 1: **강점/개선점 N: [제목]** 형식
      primary_pattern = /\*\*(?:강점|개선점|보석|숨은\s*보석)\s*(\d+):\s*\[([^\]]+)\]\*\*\n+(.*?)(?=\*\*(?:강점|개선점|보석|숨은\s*보석)\s*\d+:|$)/m
      matches = text.scan(primary_pattern)
      if matches.any?
        items = []
        matches.each do |match|
          number, title, content = match
          items << {
            number: number.to_i,
            title: title.strip,
            content: content.strip
          }
        end
        return items
      end

      # 패턴 2: 숫자. **제목** 형식
      numbered_pattern = /(\d+)\.\s*\*\*([^*]+)\*\*\n+(.*?)(?=\d+\.\s*\*\*|$)/m
      matches = text.scan(numbered_pattern)
      if matches.any?
        items = []
        matches.each do |match|
          number, title, content = match
          items << {
            number: number.to_i,
            title: title.strip,
            content: content.strip
          }
        end
        return items
      end

      # 모든 패턴이 실패하면 빈 배열 반환
      Rails.logger.warn "모든 파싱 패턴 실패"
      []
    end
  end

  # 병렬 분석 결과 조합
  def combine_analysis_results(results)
    # 텍스트 형식 (기존 호환성 유지)
    text_result = <<~COMBINED
      ## 1. 첫인상 & 전체적인 느낌

      #{results[:first_impression] || "분석 중 오류가 발생했습니다."}

      ---

      ## 2. 잘 쓴 부분 (Top 5 강점)

      #{results[:strengths] || "분석 중 오류가 발생했습니다."}

      ---

      ## 3. 아쉬운 부분 (Top 5 개선점)

      #{results[:improvements] || "분석 중 오류가 발생했습니다."}

      ---

      ## 4. 놓치고 있는 숨은 보석들

      #{results[:hidden_gems] || "분석 중 오류가 발생했습니다."}

      ---

      ## 5. 격려와 응원 메시지

      #{results[:encouragement] || "분석 중 오류가 발생했습니다."}

      ---
      💼 15년차 인사팀 선배가 드리는 진심 어린 조언
    COMBINED
  end

  # 기존 메서드를 병렬처리 버전으로 대체
  def analyze_cover_letter(content)
    # 병렬처리 사용 여부를 환경변수로 제어
    if ENV["USE_PARALLEL_ANALYSIS"] == "true"
      analyze_cover_letter_parallel(content)
    else
      # 기존 순차 처리 방식 (fallback)
      analyze_cover_letter_sequential(content)
    end
  end

  # 기존 순차 처리 방식 (이름 변경)
  def analyze_cover_letter_sequential(content, user_name = nil)
    prompt_data = @prompts.dig(:sequential_analysis)
    
    unless prompt_data
      Rails.logger.error "순차 분석 프롬프트를 찾을 수 없습니다"
      # Fallback으로 기존 프롬프트 사용
      prompt = <<~PROMPT
      ✅ 최종 자기소개서 분석용 프롬프트

      🎭 Role (역할)
      "당신은 대기업 인사팀에서 15년간 근무하며 다수의 면접관 경험을 가진 선배 인사담당자입니다.#{' '}
      #{user_name ? "#{user_name}님의" : "취업 준비생의"} 자기소개서를 읽고, HR 담당자의 시각과 따뜻한 멘토링 톤으로 깊이 있는 피드백을 제공합니다."

      ⚙️ 기본 설정
      - 답변은 매우 충분히 길고 구체적으로 작성 (각 섹션별로 지정된 최소 분량 반드시 준수)
      - 체크리스트·짧은 나열식 절대 금지 → 반드시 각 문단 5-7문장 이상의 장문으로 서술
      - 각 피드백은 HR 현장에서의 실제 시각을 담아, 지원자가 바로 개선 방향을 이해할 수 있도록
      - 공감 + 분석 + 대안 + 예시 + 멘토 코멘트까지 모두 포함
      - #{user_name ? "#{user_name}님" : "지원자님"}이라는 호칭을 자연스럽게 사용하여 친밀감 형성

      📌 출력 구조 & 지시사항

      ## 1. 첫인상 & 전체적인 느낌

      **반드시 4-5문단, 각 문단 5-7문장으로 작성**
      자기소개서를 처음 읽은 HR 담당자가 느낀 솔직하고 구체적인 인상을 서술해주세요.
      
      [1문단] 전체적인 첫인상과 구조 평가
      [2문단] 논리성과 일관성 평가 (구체적 인용 포함)
      [3문단] 진정성과 차별성 평가
      [4문단] 직무 적합성과 기업 이해도 평가
      [5문단] 종합 평가와 개선 방향 제시
      
      **절대 사용 금지 표현:**
      - "첫 문단을 읽자마자", "무릎을 쳤습니다", "눈이 번쩍 뜨였습니다"
      - "15년간 수많은 자소서를 읽어왔지만"
      - 과도한 감탄사나 극적인 표현
      
      대신 차분하고 전문적인 어조로 실제 평가를 전달하세요.

      ## 2. 잘 쓴 부분 (Top 5 강점)

      각 강점마다 최소 3-4문단, 각 문단은 4-5문장 이상으로 깊이 있게 작성. HR 현장의 실제 경험과 면접 활용 팁 포함:

      ### 1. **[핵심 강점을 한 문장으로 - 예: "고객 관점 사고를 통한 성과 창출 능력"]**

      [1문단 - 자소서 내용 인용과 첫인상] (5-7문장 필수)
      #{user_name ? "#{user_name}님의" : "지원자님의"} 자소서에서 "[실제 자소서에서 정확히 인용]"라는 부분이 특히 인상적이었습니다. 이 부분에서 [구체적인 분석]. [왜 이것이 강점인지 설명]. [실제 업무와의 연관성]. [HR 관점에서의 평가]. [다른 지원자와의 차별점]. [추가적인 의미나 가치].

      [2문단 - HR 관점에서 왜 좋은지]
      HR 현장에서 우리가 정말 찾는 인재는 '지시받은 일을 잘하는 사람'이 아니라 '왜 이 일을 해야 하는지 스스로 질문하고 답을 찾는 사람'입니다. 지원자님이 [구체적 행동]을 통해 [구체적 성과]를 만들어낸 과정은 바로 이런 사고력을 증명합니다. 특히 [특정 부분]에서 보여준 [구체적 역량]은 실제 [해당 직무]에서 가장 중요한 역량 중 하나입니다. 제가 작년에 채용한 신입사원 중에서도 이런 역량을 가진 분이 있었는데, 입사 6개월 만에 팀의 핵심 멤버로 성장했던 기억이 나네요.

      [3문단 - 차별화 포인트와 실무 연결]
      더 인상적인 점은 단순히 성과를 달성한 것에서 멈추지 않고, [후속 행동이나 학습]까지 이어간 부분입니다. 많은 지원자들이 "○○를 달성했습니다"에서 끝나는데, 지원자님은 "그래서 무엇을 배웠고, 어떻게 발전시켰는지"까지 보여주셨습니다. 이는 실무에서 '한 번의 성공을 시스템으로 만들 수 있는 사람'임을 보여주는 강력한 증거입니다.

      [4문단 - 발전 가능성과 조직 기여도] (5-7문장 필수)
      이러한 역량이 실제 조직에서 어떻게 발휘될 수 있을지 생각해보면 [구체적 예측]. [팀워크 측면에서의 기여]. [조직 문화 적합성]. [성장 잠재력 평가]. [장기적 관점에서의 가치]. [실무 적용 시 예상되는 시너지]. [종합적인 긍정 평가].

      [#고객중심사고] [#성과재현가능성] [#전략적실행]

      ### 2. **[핵심 강점을 한 문장으로]**

      [동일한 구조로 작성]

      ### 3. **[핵심 강점을 한 문장으로]**

      [동일한 구조로 작성]

      ### 4. **[핵심 강점을 한 문장으로]**

      [동일한 구조로 작성]

      ### 5. **[핵심 강점을 한 문장으로]**

      [동일한 구조로 작성]

      ## 3. 아쉬운 부분 (Top 5 개선점)

      각 개선점마다 최소 3-4문단, 각 문단은 4-5문장 이상으로 상세하게 작성. 문제점 지적 + 이유 설명 + 구체적 개선안 + 격려:

      ### 1. **[핵심 문제를 한 문장으로 - 예: "경험 나열로 인한 핵심 메시지 희석"]**

      [1문단 - 문제점 지적과 인용]
      지원자님의 자소서를 읽다가 [특정 부분]에서 잠시 멈춰서 다시 읽어봤습니다. "[실제 문장 인용]"라고 쓰신 부분인데요, 솔직히 말씀드리면 이 부분을 읽으면서 '아, 또 이런 표현이구나'라는 생각이 들었습니다. 제가 하루에 평균 50개의 자소서를 검토하는데, 이런 표현은 거의 80%의 지원자가 사용합니다. 문제는 이런 일반적인 표현이 나오는 순간, HR 담당자의 머릿속에서는 자동으로 '차별화 없음'이라는 빨간 신호가 켜진다는 것입니다. 특히 [구체적인 문제 지적] 부분은 지원자님의 진짜 역량을 가리는 안개 같은 역할을 하고 있어요.

      [2문단 - 왜 이것이 치명적인지 설명]
      이게 왜 문제인지 실제 사례로 설명드릴게요. 작년에 비슷한 자소서를 쓴 두 명의 지원자가 있었습니다. A는 "열정적이고 도전적인 성격으로 모든 일에 최선을 다합니다"라고 썼고, B는 "매일 아침 6시에 출근해 경쟁사 마케팅 동향을 분석하는 리포트를 3개월간 작성했고, 이를 통해 우리 팀이 놓치고 있던 타겟층을 발견해 신규 캠페인으로 연결시켰습니다"라고 썼죠. 누가 합격했을까요? 당연히 B입니다. HR 입장에서는 '무엇을 할 수 있는 사람인지'가 명확히 보이는 지원자를 선호합니다. 막연한 성격 묘사는 아무런 정보를 주지 못해요.

      [3문단 - 구체적인 개선 방향과 예시]
      이 부분을 이렇게 바꿔보시면 어떨까요? 현재의 "[원래 표현]" 대신 "[개선된 구체적 예시 - 상황/행동/결과 포함]"라고 쓰는 겁니다. 예를 들어, "저는 책임감이 강합니다"가 아니라 "프로젝트 마감 3일 전 팀원이 갑자기 이탈했을 때, 제가 그의 파트까지 맡아 48시간 동안 집중 작업하여 기한 내 완성했고, 클라이언트로부터 '위기 대처 능력이 뛰어나다'는 평가를 받았습니다"라고 쓰는 거죠. 이렇게 쓰면 면접관이 '아, 이 사람은 실제로 위기 상황에서 책임감 있게 행동한 경험이 있구나'라고 구체적으로 이해할 수 있습니다.

      [4문단 - 격려와 실행 가능한 조언]
      지원자님, 분명히 이런 구체적인 경험들이 있으실 거예요. 단지 그것을 '일반적인 표현'이라는 포장지로 감싸버리신 것뿐입니다. 자소서를 다시 읽으면서 모든 형용사와 추상적 표현에 형광펜을 쳐보세요. 그리고 각각에 대해 "이걸 증명할 수 있는 나만의 에피소드가 뭐지?"라고 자문해보세요. 그 에피소드를 숫자와 구체적 상황으로 풀어쓰면, 지금보다 10배는 강력한 자소서가 될 겁니다. 저는 지원자님이 충분히 그럴 역량이 있다고 확신합니다.

      [#구체성강화] [#차별화전략] [#STAR기법적용]

      ### 2. **[핵심 문제를 한 문장으로]**

      [동일한 구조로 작성]

      ### 3. **[핵심 문제를 한 문장으로]**

      [동일한 구조로 작성]

      ### 4. **[핵심 문제를 한 문장으로]**

      [동일한 구조로 작성]

      ### 5. **[핵심 문제를 한 문장으로]**

      [동일한 구조로 작성]

      ## 4. 놓치고 있는 숨은 보석들

      각 숨은 강점마다 최소 2-3문단, 각 문단은 4-5문장 이상으로 깊이 있게 작성:

      ### 1. **[발견한 잠재 강점을 한 문장으로 - 예: "관찰력이라는 차별화된 무기"]**

      [1문단 - 발견의 순간과 놀라움]
      지원자님의 자소서를 세 번째 읽다가 갑자기 "어?"하고 멈춰 섰습니다. [특정 부분]에서 아주 짧게, 거의 스쳐 지나가듯 언급하신 "[구체적 문장 인용]"라는 부분 말입니다. 대부분의 지원자는 이런 디테일을 놓치는데, 지원자님은 이걸 포착하고 행동으로 옮기셨더군요. 15년간 HR 업무를 하면서 이런 관찰력을 가진 지원자는 손에 꼽을 정도였습니다. 그런데 왜 이렇게 중요한 역량을 한 줄로만 처리하셨나요? 이건 정말 아까운 일입니다.

      [2문단 - 왜 이것이 보석인지 설명]
      제가 왜 이렇게 흥분하는지 설명드릴게요. 현재 [관련 업계/직무]에서 가장 부족한 인재가 바로 '디테일을 캐치하고 인사이트로 전환할 수 있는 사람'입니다. 실제로 작년에 우리 회사에서 대박을 친 [예시 프로젝트/캠페인]도 누군가의 작은 관찰에서 시작됐거든요. 지원자님이 [구체적 상황]에서 [구체적 관찰]을 통해 [구체적 결과]를 만들어낸 것은, 단순한 성과가 아니라 '남들이 보지 못하는 것을 보는 눈'을 가졌다는 증거입니다. 이런 능력은 가르쳐서 되는 게 아니라 타고나는 거예요.

      [3문단 - 어떻게 활용하고 강조할지 구체적 제안]
      제발 이 부분을 전면에 내세우세요! 자소서에서 별도 섹션으로 만들어서 "저는 작은 신호에서 큰 기회를 발견하는 관찰력을 가지고 있습니다"라고 시작하면서, 이 경험을 STAR 구조로 풀어쓰시면 됩니다. 면접에서는 "사실 제가 가장 자신 있는 역량이 있는데요"라고 운을 떼고 이 이야기를 하세요. 면접관들이 "이런 시각을 가진 사람이라면 우리 팀에서 새로운 관점을 제시해줄 수 있겠다"라고 생각할 겁니다. 이미 경험이 있으니 자신감을 가지고 어필하세요!

      [#숨은역량발굴] [#관찰력] [#차별화포인트]

      ### 2. **[발견한 잠재 강점을 한 문장으로]**

      [동일한 구조로 작성]

      ### 3. **[발견한 잠재 강점을 한 문장으로]**

      [동일한 구조로 작성]

      [5문단 - 마지막 당부]
      마지막으로 꼭 기억하셨으면 하는 게 있어요. 자소서는 '완벽한 사람'을 보여주는 문서가 아니라, '함께 일하고 싶은 사람'을 보여주는 문서입니다. 너무 완벽하려고 하지 마시고, 지원자님의 진짜 모습을 전략적으로 보여주세요. 실수도 했고, 실패도 했지만, 그것을 통해 성장한 '인간적인 프로페셔널'의 모습을 보여주세요. 그것이 바로 우리가 찾는 인재의 모습이니까요. 지원자님의 합격 소식을 진심으로 기다리겠습니다. 화이팅!

      ---
      💼 15년차 인사팀 선배가 드리는 진심 어린 조언

      자기소개서 내용:
      #{content}
    PROMPT
    else
      # 프롬프트 파일에서 로드된 프롬프트 사용
      prompt = prompt_data[:prompt]
      prompt = prompt.gsub("{{user_name}}", user_name || "지원자")
      prompt = prompt.gsub("{{content}}", content)
    end

    max_tokens = prompt_data ? (prompt_data[:max_tokens] || 8000) : 8000
    response = make_api_request(prompt, "대기업 인사팀 15년 경력 선배", max_tokens)
    parse_response(response)[:content]
  end

  # [DEPRECATED] 기업 분석을 사용하는 기존 메서드 - 현재 미사용
  # def generate_customized_letter(company_name, position, company_analysis, cl_analysis, original_content)
  #   prompt = <<~PROMPT
  #     당신은 전문 자기소개서 작성 컨설턴트입니다.

  #     **주어진 정보:**
  #     - 목표 기업: #{company_name}
  #     - 지원 직무: #{position}
  #     - 기업 분석 결과:
  #     #{company_analysis}

  #     - 지원자 분석 결과:
  #     #{cl_analysis}

  #     - 기존 자기소개서:
  #     #{original_content}

  #     **작성 가이드라인:**
  #     1. 기업의 현안과 지원자 경험을 자연스럽게 연결
  #     2. 기업이 원하는 인재상에 맞춰 강점 부각
  #     3. 구체적 수치와 성과로 신뢰성 확보
  #     4. 기업 키워드를 자연스럽게 포함
  #     5. 차별화된 인사이트와 관점 제시

  #     **출력 형식:**
  #     ## ✨ #{company_name} 맞춤 자기소개서

  #     ### 지원동기 및 포부
  #     [기업 현안과 연결된 개인 경험을 바탕으로 한 답변]
  #     - 기업 이슈 반영: [어떤 현안을 어떻게 반영했는지]
  #     - 차별화 포인트: [다른 지원자와 구별되는 관점]

  #     ### 직무 역량 및 경험
  #     [직무와 관련된 구체적 경험과 성과]
  #     - 핵심 역량 강조: [기업이 원하는 역량과 매칭]
  #     - 성과 수치화: [구체적 숫자와 임팩트]

  #     ### 입사 후 포부
  #     [기업의 미래 방향성과 연계한 비전]
  #     - 기여 방안: [구체적인 기여 계획]
  #     - 성장 비전: [장기적 목표]

  #     **💡 작성 인사이트:**
  #     - 활용된 기업 현안: [리스트]
  #     - 강조된 개인 역량: [리스트]
  #     - 차별화 전략: [설명]
  #   PROMPT

  #   response = make_api_request(prompt, "자기소개서 작성 컨설턴트", 6000)
  #   parse_response(response)[:content]
  # end

  # 피드백 기반 개선된 자기소개서 생성
  # rewrite_mode: 'preserve' (원본 유지) 또는 'optimize' (AI 최적화)
  def generate_improved_letter(original_content, feedback_analysis, company_name = nil, position = nil, rewrite_mode = "preserve")
    # 원본에서 항목 추출
    original_sections = extract_sections_from_content(original_content)
    
    Rails.logger.info "원본 섹션 수: #{original_sections.length}"
    Rails.logger.info "원본 섹션 제목: #{original_sections.map { |s| s[:title] }.join(', ')}"

    # 원본 섹션이 있는 경우 항상 원본 구조 유지
    if original_sections.length > 1
      sections_list = original_sections.map { |s| "#{s[:number]}. #{s[:title]}" }.join("\n")
      
      mode_instruction = <<~MODE
        ⭐️ 원본 구조 유지 모드:
        
        **원본 자소서의 항목을 100% 동일하게 유지해야 합니다!**
        
        원본 자소서의 섹션 구조:
        #{sections_list}
        
        위 #{original_sections.length}개 항목을 정확히 동일한 순서와 제목으로 유지하세요.
        각 항목의 내용만 개선하고, 항목 번호와 제목은 절대 변경하지 마세요.
      MODE
    elsif rewrite_mode == "optimize"
      # 섹션이 하나뿐이고 optimize 모드일 때만 새로운 구조 제안
      mode_instruction = <<~MODE
        ⭐️ AI 최적화 모드:
        원본 내용을 바탕으로 아래 6개 섹션으로 구성된 자소서를 작성하세요:
        
        **반드시 아래 6개 섹션으로 작성:**
        1. 지원 동기
        2. 성장 과정
        3. 직무 역량
        4. 협업 경험
        5. 도전 정신
        6. 입사 후 포부

        원본 내용을 위 6개 구조에 맞게 재구성하되, 원본의 핵심 내용은 모두 포함시켜주세요.
      MODE
    else
      # 섹션이 하나뿐이고 preserve 모드일 때
      mode_instruction = <<~MODE
        ⭐️ 원본 구조 개선 모드:
        원본 자소서가 구조화되지 않았으므로, 아래 4개 섹션으로 구성하여 작성하세요:
        
        **반드시 아래 4개 섹션으로 작성:**
        1. 지원 동기
        2. 핵심 경험과 역량
        3. 협업과 성장
        4. 입사 후 포부
      MODE
    end

    prompt = <<~PROMPT
      당신은 대기업 인사팀에서 15년 이상 근무하며 수백 명의 지원서를 검토하고 면접관으로 활동해온 HR 전문가이자 멘토입니다.
      아래에는 [지원자의 자기소개서 원본]과 [분석 피드백]이 있습니다.

      👉 목적:
      분석 피드백을 100% 반영하여 자기소개서를 **구체적이고 진정성 있게 리라이트**하세요.

      #{mode_instruction}

      ⭐️⭐️⭐️ 매우 중요한 출력 형식 규칙 ⭐️⭐️⭐️
      
      **반드시 각 섹션을 아래 형식으로 작성하세요:**
      
      1. [섹션 제목]
      [한 줄 캐치프레이즈]

      (실제 내용...)

      2. [다음 섹션 제목]
      [한 줄 캐치프레이즈]

      (실제 내용...)

      **구체적 예시:**
      1. 지원 동기
      [고객 중심 마케팅으로 일상의 혁신을 만들어가는 여정]

      (첫 번째 문단 - 도입부: 나의 관심사와 기업 연결)
      저는 변화의 흐름을 주도하며 고객의 삶에 실질적 가치를 더하는 마케팅을 꿈꿔왔습니다...

      (두 번째 문단 - 중간부: 구체적 경험과 성과)
      대학 시절 링커리어 콘텐츠 에디터로 활동하면서...

      (세 번째 문단 - 마무리: 입사 후 포부와 비전)
      삼성전자의 마케팅팀에서 고객의 목소리를 진정성 있게 듣고...

      👉 작성 규칙:
      1. **반드시 여러 개의 섹션으로 나누어 작성합니다.**
      2. **각 섹션은 "숫자. 섹션명" 형식으로 시작합니다** (예: 1. 지원 동기, 2. 성장 과정)
      3. 각 섹션마다 반드시 [한 줄 캐치프레이즈] 포함
      4. 각 섹션은 2-3개 문단으로 구성 (각 문단 4-5문장)
      5. 섹션 사이에 빈 줄 삽입으로 구분
      6. 피드백에서 제시된 모든 개선점을 반드시 수정하여 반영합니다:
         - 경험 나열로 인한 핵심 메시지 희석 → 각 경험의 의미를 명확히 구분
         - 자기만의 색깔 부족 → 차별화된 시각과 독특한 경험 부각
         - 과정과 내면 서사 부족 → 고민과 시행착오, 성찰 과정 추가
         - 회사 맞춤형 동기 부족 → 지원 기업만의 특성과 연결
      7. 모든 경험은 **상황 → 행동 → 성과 → 배운 점 → 직무 연결**의 구조로 작성
      8. STAR 기법(Situation-Task-Action-Result)을 철저히 적용
      9. 글 전체의 톤은 진정성 있고 설득력 있게, HR 담당자가 읽기 편한 문체로 작성
      10. **격려 멘토 코멘트는 포함하지 않고, 최종 자기소개서 원고 형태로만 출력**

      #{company_name ? "📌 지원 기업: #{company_name}" : ""}
      #{position ? "📌 지원 직무: #{position}" : ""}

      [지원자의 자기소개서 원본]
      ───────────────────────────────────────────────────────────
      #{original_content}
      ───────────────────────────────────────────────────────────

      [분석 피드백]
      ───────────────────────────────────────────────────────────
      #{feedback_analysis}
      ───────────────────────────────────────────────────────────

      👉 출력:
      위 분석 피드백을 충실히 반영한 **최종 자기소개서 리라이트 버전**을 작성해 주세요.

      ⚠️⚠️⚠️ 출력 형식 - 절대 규칙 ⚠️⚠️⚠️
      
      #{if original_sections.length > 1
        "**원본 자소서의 섹션 구조를 정확히 따라서 출력하세요:**\n\n" +
        original_sections.map { |s| 
          "#{s[:number]}. #{s[:title]}\n[캐치프레이즈]\n\n(내용...)\n"
        }.join("\n")
      else
        <<~FORMAT
          반드시 아래와 같은 형식으로 여러 섹션으로 나누어 출력하세요:
          
          1. [첫 번째 섹션 제목]
          [캐치프레이즈]
          
          (내용...)
          
          2. [두 번째 섹션 제목]
          [캐치프레이즈]
          
          (내용...)
          
          3. [세 번째 섹션 제목]
          [캐치프레이즈]
          
          (내용...)
          
          (이하 모든 섹션...)
        FORMAT
      end}
      
      **중요: 각 섹션은 반드시 "숫자. 제목" 형식으로 시작하고, 그 다음 줄에 [캐치프레이즈]를 포함하세요!**
    PROMPT

    # max_tokens를 충분히 크게 설정
    response = make_api_request(prompt, "자기소개서 리라이팅 HR 전문가", 12000)

    # 응답에서 불필요한 메타 텍스트 제거
    content = parse_response(response)[:content] || ""

    # 내용이 너무 짧으면 에러 로그
    if content.length < 2000
      Rails.logger.error "리라이트 결과가 너무 짧음: #{content.length}자"
      Rails.logger.error "원본 응답의 첫 500자: #{content[0..500]}"
    end

    content
  end

  # 자기소개서 분석 결과 포맷팅
  def format_cover_letter_analysis(analysis)
    <<~FORMATTED
      ═══════════════════════════════════════════════════════════
      📝 자기소개서 심층 분석 결과
      ═══════════════════════════════════════════════════════════

      #{analysis}

      ═══════════════════════════════════════════════════════════
      💡 분석 완료 | HR 멘토링 관점 피드백
      ═══════════════════════════════════════════════════════════
    FORMATTED
  end

  # 간단한 전체 분석 포맷팅 (기업 분석 제외)
  def format_full_analysis_simple(cover_letter_analysis, customized_letter)
    <<~ANALYSIS
      ═══════════════════════════════════════════════════════════
      🎯 AI 자기소개서 분석 및 개선 완료
      ═══════════════════════════════════════════════════════════

      ## 📝 자기소개서 분석
      ───────────────────────────────────────────────────────────
      #{cover_letter_analysis}

      ## ✨ 개선된 자기소개서
      ───────────────────────────────────────────────────────────
      #{customized_letter}

      ═══════════════════════════════════════════════════════════
      💼 분석 완료 | Powered by GPT-4o
      ═══════════════════════════════════════════════════════════
    ANALYSIS
  end

  def format_full_analysis(company_analysis, cl_analysis, customized_letter)
    <<~ANALYSIS
      ═══════════════════════════════════════════════════════════
      🎯 AI 자기소개서 3단계 심층 분석 완료
      ═══════════════════════════════════════════════════════════

      #{company_analysis}

      ───────────────────────────────────────────────────────────

      #{cl_analysis}

      ───────────────────────────────────────────────────────────

      #{customized_letter}

      ═══════════════════════════════════════════════════════════
      💼 분석 완료 | Powered by GPT-4o
      ═══════════════════════════════════════════════════════════
    ANALYSIS
  end

  def make_api_request(prompt, role_description, max_tokens = 3000)
    uri = URI(OPENAI_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 180  # 3분으로 증가

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"

    # 강화된 시스템 프롬프트
    system_prompt = <<~SYSTEM
      당신은 #{role_description}입니다.
      한국 기업과 채용 시장에 대한 깊은 이해를 바탕으로 전문적이고 실용적인 조언을 제공합니다.
      
      🔴 절대 준수 규칙:
      1. 프롬프트에서 요구한 분량을 반드시 충족시켜야 합니다
      2. 각 문단은 지정된 문장 수(5-7문장)를 준수합니다
      3. 형식 지시사항([1문단], [2문단] 등)을 정확히 따릅니다
      4. 축약이나 생략 없이 완전한 내용을 출력합니다
      5. 토큰이 부족하더라도 핵심 내용은 모두 포함시킵니다
    SYSTEM

    request.body = {
      model: @model,
      messages: [
        {
          role: "system",
          content: system_prompt
        },
        {
          role: "user",
          content: prompt
        }
      ],
      temperature: 0.3,  # 더 일관된 출력을 위해 낮춤
      max_tokens: max_tokens,
      presence_penalty: 0.1,  # 반복 방지
      frequency_penalty: 0.1   # 다양성 증가
    }.to_json

    response = http.request(request)
    JSON.parse(response.body)
  end

  def parse_response(response)
    if response["error"]
      { error: response["error"]["message"] }
    elsif response["choices"] && response["choices"].first
      {
        success: true,
        content: response["choices"].first["message"]["content"],
        usage: response["usage"]
      }
    else
      { error: "\uC608\uC0C1\uCE58 \uBABB\uD55C \uC751\uB2F5 \uD615\uC2DD\uC785\uB2C8\uB2E4" }
    end
  end

  def extract_sections_from_content(content)
    # 자소서 내용을 섹션별로 분리
    sections = []
    
    # 다양한 섹션 패턴 지원
    # 1. 숫자. 제목 (예: "1. 지원 동기")
    # 2. [제목] (예: "[지원 동기]")
    # 3. Q1. 제목 (예: "Q1. 지원 동기")
    # 4. 문항1) 제목 (예: "문항1) 지원 동기")
    
    # 먼저 숫자. 패턴 시도
    if content.match(/^\d+\.\s+/m)
      parts = content.split(/(?=^\d+\.\s+)/m)
      parts = parts.reject(&:blank?)
      
      parts.each_with_index do |part, idx|
        if part.match(/^(\d+)\.\s+(.+?)[\n\r]/)
          number = $1
          title = $2.strip
          body_start = part.index("\n") || part.length
          body = part[body_start..-1]&.strip || ""
          
          sections << {
            number: number.to_i,
            title: title,
            content: body
          }
        end
      end
    # Q 패턴 시도
    elsif content.match(/^Q\d+\.\s+/m)
      parts = content.split(/(?=^Q\d+\.\s+)/m)
      parts = parts.reject(&:blank?)
      
      parts.each_with_index do |part, idx|
        if part.match(/^Q(\d+)\.\s+(.+?)[\n\r]/)
          number = $1
          title = $2.strip
          body_start = part.index("\n") || part.length
          body = part[body_start..-1]&.strip || ""
          
          sections << {
            number: number.to_i,
            title: title,
            content: body
          }
        end
      end
    # 문항 패턴 시도
    elsif content.match(/^문항\s*\d+\)/m)
      parts = content.split(/(?=^문항\s*\d+\))/m)
      parts = parts.reject(&:blank?)
      
      parts.each_with_index do |part, idx|
        if part.match(/^문항\s*(\d+)\)\s*(.+?)[\n\r]/)
          number = $1
          title = $2.strip
          body_start = part.index("\n") || part.length
          body = part[body_start..-1]&.strip || ""
          
          sections << {
            number: number.to_i,
            title: title,
            content: body
          }
        end
      end
    # [제목] 패턴 시도
    elsif content.match(/^\[.+\]/m)
      parts = content.split(/(?=^\[)/m)
      parts = parts.reject(&:blank?)
      
      parts.each_with_index do |part, idx|
        if part.match(/^\[(.+?)\]/)
          title = $1.strip
          body_start = part.index("\n") || part.length
          body = part[body_start..-1]&.strip || ""
          
          sections << {
            number: idx + 1,
            title: title,
            content: body
          }
        end
      end
    end

    # 섹션이 없으면 전체를 하나의 섹션으로 처리
    if sections.empty?
      # 간단한 자소서일 경우 기본 섹션 생성
      sections << {
        number: 1,
        title: "자기소개서",
        content: content.strip
      }
    end

    sections
  end

  # Python을 사용한 텍스트 파싱
  def parse_with_python(text)
    return [] if text.blank?

    begin
      python_script = Rails.root.join("lib", "python", "korean_text_analyzer.py")

      # Python 스크립트에 텍스트 전달
      input_data = { text: text, action: "parse_numbered_items" }.to_json

      stdout, stderr, status = Open3.capture3(
        "python3", python_script.to_s,
        stdin_data: input_data
      )

      if status.success?
        result = JSON.parse(stdout)
        if result["success"]
          items = result["items"] || []
          # Hash 키를 심볼로 변환
          items.map do |item|
            {
              number: item["number"] || item[:number],
              title: item["title"] || item[:title],
              content: item["content"] || item[:content]
            }
          end
        else
          Rails.logger.warn "Python 파싱 실패: #{result['error']}"
          []
        end
      else
        Rails.logger.warn "Python 파싱 프로세스 실패: #{stderr}"
        []
      end

    rescue JSON::ParserError => e
      Rails.logger.warn "Python 파싱 결과 JSON 파싱 실패: #{e.message}"
      []
    rescue => e
      Rails.logger.warn "Python 파싱 중 예외 발생: #{e.message}"
      []
    end
  end

  # 분석 결과 텍스트를 구조화된 JSON으로 파싱
  def parse_analysis_to_json(analysis_text)
    return nil if analysis_text.blank?
    
    sections = []
    current_section = nil
    current_item = nil
    
    analysis_text.lines.each do |line|
      line = line.strip
      
      # 메인 섹션 (## 으로 시작)
      if line =~ /^##\s*(\d+)\.\s*(.+)$/
        # 이전 항목 저장
        if current_item && current_section
          current_section['items'] ||= []
          current_section['items'] << current_item
          current_item = nil
        end
        
        # 이전 섹션 저장
        sections << current_section if current_section
        
        current_section = {
          'number' => $1,
          'title' => $2.strip,
          'content' => '',
          'items' => []
        }
        
      # 서브 항목 (### 으로 시작 - 강점, 개선점, 보석)
      elsif line =~ /^###\s*(강점|개선점|보석)\s*(\d+)[:：]\s*(.+)$/
        # 이전 항목 저장
        if current_item && current_section
          current_section['items'] << current_item
        end
        
        current_item = {
          'type' => $1.strip,
          'number' => $2,
          'title' => $3.strip,
          'content' => ''
        }
        
      # 대괄호로 시작하는 소제목
      elsif line =~ /^\[(.+)\]$/ && current_item
        current_item['content'] += "\n" unless current_item['content'].empty?
        current_item['content'] += line
        
      # 빈 줄이 아닌 일반 내용
      elsif !line.empty?
        if current_item
          # 항목에 내용 추가
          current_item['content'] += "\n" unless current_item['content'].empty?
          current_item['content'] += line
        elsif current_section
          # 섹션에 내용 추가
          current_section['content'] += "\n" unless current_section['content'].empty?
          current_section['content'] += line
        end
      end
    end
    
    # 마지막 항목과 섹션 저장
    if current_item && current_section
      current_section['items'] << current_item
    end
    sections << current_section if current_section
    
    {
      'sections' => sections,
      'parsed_at' => Time.current.iso8601
    }
  rescue => e
    Rails.logger.error "Analysis parsing error: #{e.message}"
    nil
  end
end
