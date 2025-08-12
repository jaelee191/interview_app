require 'net/http'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'playwright'

class JobPostingAnalyzerService
  OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions'
  
  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    @model = ENV['OPENAI_MODEL'] || 'gpt-4.1'
  end
  
  def analyze_job_text(company_name, position, content, source_url = nil)
    return { error: "API 키가 설정되지 않았습니다" } unless @api_key
    return { error: "필수 정보를 모두 입력해주세요" } if company_name.blank? || position.blank? || content.blank?
    
    begin
      Rails.logger.info "텍스트 기반 채용공고 분석 시작"
      Rails.logger.info "회사: #{company_name}, 직무: #{position}"
      
      # 직접 입력된 텍스트로 AI 분석
      analysis = analyze_with_ai_direct(company_name, position, content, source_url)
      
      {
        success: true,
        company_name: company_name,
        position: position,
        analysis: analysis,
        timestamp: Time.current
      }
    rescue StandardError => e
      Rails.logger.error "채용공고 텍스트 분석 오류: #{e.message}"
      { error: "분석 중 오류가 발생했습니다: #{e.message}" }
    end
  end
  
  def analyze_job_posting(url, job_title = nil)
    return { error: "API 키가 설정되지 않았습니다" } unless @api_key
    return { error: "URL을 입력해주세요" } if url.blank?
    
    begin
      # 1단계: 웹페이지 크롤링
      Rails.logger.info "채용공고 크롤링 시작: #{url}"
      content = fetch_job_posting_content(url, job_title)
      
      return { error: "채용공고 내용을 가져올 수 없습니다" } if content.blank?
      
      # 2단계: AI 분석
      Rails.logger.info "AI 분석 시작"
      analysis = analyze_with_ai(content, url)
      
      # 3단계: 구조화된 결과 반환
      {
        success: true,
        url: url,
        raw_content: content,
        analysis: analysis,
        timestamp: Time.current
      }
    rescue StandardError => e
      Rails.logger.error "채용공고 분석 오류: #{e.message}"
      { error: "분석 중 오류가 발생했습니다: #{e.message}" }
    end
  end
  
  private
  
  def fetch_job_posting_content(url, job_title = nil)
    # 캐시 확인
    cached_content = JobPostingCache.fetch(url)
    if cached_content.present?
      Rails.logger.info "캐시에서 컨텐츠 로드: #{url}"
      return cached_content
    end
    
    # 주요 채용 사이트별 크롤링 전략
    content = case url
    when /samsungcareers\.com/
      fetch_samsung_content(url, job_title)
    when /saramin\.co\.kr/
      fetch_saramin_content(url)
    when /jobkorea\.co\.kr/
      fetch_jobkorea_content(url)
    when /wanted\.co\.kr/
      fetch_wanted_content(url)
    when /incruit\.com/
      fetch_incruit_content(url)
    when /jobplanet\.co\.kr/
      fetch_jobplanet_content(url)
    else
      fetch_general_content(url)
    end
    
    # 성공적으로 크롤링한 경우 캐싱
    if content.present? && content.length > 100
      JobPostingCache.store(url, content)
    end
    
    content
  end
  
  def fetch_general_content(url)
    # 일반적인 웹페이지 크롤링
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    
    return nil unless response.is_a?(Net::HTTPSuccess)
    
    doc = Nokogiri::HTML(response.body)
    
    # 본문 텍스트 추출 (다양한 선택자 시도)
    content = ""
    
    # 메타 정보 추출
    meta_description = doc.at('meta[name="description"]')&.attr('content')
    content += "설명: #{meta_description}\n\n" if meta_description
    
    # 제목 추출
    title = doc.at('title')&.text&.strip
    content += "제목: #{title}\n\n" if title
    
    # 본문 추출 (여러 선택자 시도)
    selectors = [
      'main', 'article', '[role="main"]', 
      '.content', '.job-content', '.posting-content',
      '#content', '#job-content', '#posting-content',
      '.description', '.job-description', '.detail'
    ]
    
    selectors.each do |selector|
      element = doc.at(selector)
      if element
        text = element.text.gsub(/\s+/, ' ').strip
        content += text if text.length > 100
        break
      end
    end
    
    # 본문이 없으면 전체 body에서 추출
    if content.length < 200
      body_text = doc.at('body')&.text&.gsub(/\s+/, ' ')&.strip
      content = body_text[0..5000] if body_text # 최대 5000자
    end
    
    content
  end
  
  def fetch_samsung_content(url, job_title = nil)
    # 삼성 채용 사이트는 JavaScript 렌더링이 필요하므로
    # URL 정보와 사용자 제공 정보를 결합
    Rails.logger.info "삼성 채용 사이트 분석: #{url}"
    Rails.logger.info "채용공고 제목: #{job_title}" if job_title.present?
    
    # URL에서 공고 번호 추출
    job_id = url.match(/no=(\d+)/)&.captures&.first
    
    # 사용자가 제공한 제목이 있으면 우선 사용
    if job_title.present?
      content = <<~CONTENT
        채용 사이트: 삼성 공식 채용 사이트 (samsungcareers.com)
        채용공고 URL: #{url}
        공고 번호: #{job_id}
        
        **채용공고 제목: #{job_title}**
        
        이 채용공고는 #{job_title}에 대한 것입니다.
        
        제목을 분석하면:
        #{parse_job_title_details(job_title)}
        
        삼성 채용의 일반적 특징:
        - 체계적인 전형 절차 (서류 → 인적성 → 면접)
        - 직무별 전문성 중시
        - 글로벌 역량 우대
        - 삼성 핵심가치 (도전, 창조, 변화) 중시
      CONTENT
    else
      # 제목이 없으면 일반적인 삼성 채용 정보 제공
      content = <<~CONTENT
        채용 사이트: 삼성 공식 채용 사이트 (samsungcareers.com)
        채용공고 URL: #{url}
        공고 번호: #{job_id}
        
        삼성 계열사 채용공고 (상세 정보는 사이트에서 확인 필요)
        
        일반적으로 삼성 채용공고는:
        - 모집 부문 및 직무
        - 자격 요건 (학력, 경력, 필수 역량)
        - 우대 사항
        - 근무 조건 및 처우
        - 전형 절차
      CONTENT
    end
    
    content
  end
  
  def parse_job_title_details(title)
    details = []
    
    # 회사명 추출
    if title.include?("삼성물산")
      details << "- 회사: 삼성물산"
      if title.include?("패션")
        details << "- 사업부문: 패션부문 (SSF, 빈폴, 갤럭시, 로가디스 등 브랜드 운영)"
      end
    elsif title.include?("삼성전자")
      details << "- 회사: 삼성전자"
    elsif title.include?("삼성SDS")
      details << "- 회사: 삼성SDS"
    end
    
    # 경력 구분
    if title.include?("경력")
      details << "- 모집구분: 경력사원"
    elsif title.include?("신입")
      details << "- 모집구분: 신입사원"
    end
    
    # 직무 추출
    jobs = []
    jobs << "퍼포먼스마케팅" if title.include?("퍼포먼스마케팅")
    jobs << "CRM" if title.include?("CRM")
    jobs << "브랜드마케팅" if title.include?("브랜드마케팅")
    jobs << "수출입관리" if title.include?("수출입")
    jobs << "아키텍처설계" if title.include?("아키텍처")
    jobs << "조리사" if title.include?("조리사")
    
    if jobs.any?
      details << "- 모집직무: #{jobs.join(', ')}"
    end
    
    details.join("\n")
  end
  
  def fetch_saramin_content(url)
    # Playwright를 사용한 사람인 동적 크롤링
    Rails.logger.info "Playwright로 사람인 크롤링 시작: #{url}"
    
    begin
      Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
        playwright.chromium.launch(headless: true) do |browser|
          context = browser.new_context(
            viewport: { width: 1920, height: 1080 },
            userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
          )
          
          page = context.new_page
          
          # 페이지 로드
          page.goto(url, waitUntil: 'domcontentloaded')
          
          # JavaScript 렌더링 대기
          sleep(3)
          
          # HTML 가져오기
          html = page.content
          doc = Nokogiri::HTML(html)
          
          content = ""
          
          # 회사명 추출 (Nokogiri 사용)
          company = doc.at('.company_name a')&.text&.strip ||
                    doc.at('.co_name a')&.text&.strip ||
                    doc.at('[class*="company"]')&.text&.strip
          
          # 직무명 추출 (Nokogiri 사용)
          position = doc.at('.job_tit .tit')&.text&.strip ||
                     doc.at('h1.tit_job')&.text&.strip ||
                     doc.at('[class*="job_tit"]')&.text&.strip
          
          # 타이틀에서 추출 시도
          if (!company || !position)
            title = page.title
            if title =~ /\[(.*?)\]\s*(.+?)\s*(-|\||사람인)/
              company ||= $1.strip
              position ||= $2.strip
            end
          end
          
          content += "회사: #{company}\n" if company
          content += "직무: #{position}\n\n" if position
          
          # 상세 정보 추출 (Nokogiri 사용)
          # 근무지역
          location = doc.at('dt:contains("근무지역") + dd')&.text&.strip ||
                    doc.at('.jv_location')&.text&.strip
          content += "근무지역: #{location}\n" if location
          
          # 경력
          career = doc.at('dt:contains("경력") + dd')&.text&.strip ||
                  doc.at('.career')&.text&.strip
          content += "경력: #{career}\n" if career
          
          # 학력
          education = doc.at('dt:contains("학력") + dd')&.text&.strip ||
                     doc.at('.education')&.text&.strip
          content += "학력: #{education}\n" if education
          
          # 고용형태
          employment = doc.at('dt:contains("고용형태") + dd')&.text&.strip
          content += "고용형태: #{employment}\n" if employment
          
          # 급여
          salary = doc.at('dt:contains("급여") + dd')&.text&.strip
          content += "급여: #{salary}\n" if salary
          
          # 직무 내용
          job_content = doc.at('.jv_cont, .user_content, .wrap_jv_cont')&.text&.strip
          if job_content && job_content.length > 100
            job_content = job_content[0..3000] if job_content.length > 3000
            content += "\n직무 내용:\n#{job_content}\n"
          end
          
          # 우대사항
          prefer = doc.at('dt:contains("우대사항") + dd')&.text&.strip
          content += "\n우대사항: #{prefer}\n" if prefer
          
          # 복리후생
          welfare = doc.at('dt:contains("복리후생") + dd')&.text&.strip
          content += "복리후생: #{welfare}\n" if welfare
          
          # 컨텐츠가 없으면 전체 텍스트 사용
          if content.length < 200
            Rails.logger.warn "구조화된 데이터 부족, 전체 텍스트 사용"
            full_text = doc.text.gsub(/\s+/, ' ').strip
            content = "URL: #{url}\n\n#{full_text[0..5000]}"
          end
          
          Rails.logger.info "Playwright 사람인 크롤링 완료: #{content.length} 글자"
          
          context.close
          return content
        end
      end
    rescue StandardError => e
      Rails.logger.error "Playwright 크롤링 실패: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n") if e.backtrace
      
      # Playwright 실패 시 기본 방식으로 폴백
      return fetch_saramin_content_fallback(url)
    end
  end
  
  def fetch_saramin_content_fallback(url)
    # 기본 HTTP 방식 (폴백)
    Rails.logger.info "폴백: 기본 HTTP 방식으로 사람인 크롤링"
    
    begin
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 10
      
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
      request['Accept'] = 'text/html,application/xhtml+xml'
      
      response = http.request(request)
      
      # 리다이렉트 처리
      if response.code == '301' || response.code == '302'
        location = response['Location']
        if location && location.start_with?('http')
          return fetch_general_content(location)
        end
      end
      
      doc = Nokogiri::HTML(response.body)
      page_text = doc.text.gsub(/\s+/, ' ').strip
      return "URL: #{url}\n\n#{page_text[0..5000]}"
      
    rescue StandardError => e
      Rails.logger.error "폴백도 실패: #{e.message}"
      return fetch_general_content(url)
    end
  end
  
  
  def fetch_jobkorea_content(url)
    # Playwright를 사용한 잡코리아 동적 크롤링
    Rails.logger.info "Playwright로 잡코리아 크롤링: #{url}"
    
    begin
      Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
        playwright.chromium.launch(headless: true) do |browser|
          page = browser.new_page
          page.goto(url, waitUntil: 'domcontentloaded')
          sleep(2)
          
          # HTML 가져오기
          html = page.content
          doc = Nokogiri::HTML(html)
          
          content = ""
          
          # 회사명
          company = doc.at('.co-name a, .company-name')&.text&.strip
          content += "회사: #{company}\n" if company
          
          # 직무명
          position = doc.at('.tit-job, h2.job-title')&.text&.strip
          content += "직무: #{position}\n\n" if position
          
          # 직무 상세
          job_detail = doc.at('.job-detail')&.text&.strip
          content += "\n직무 상세:\n#{job_detail}\n" if job_detail
          
          Rails.logger.info "잡코리아 크롤링 완료: #{content.length} 글자"
          
          return content.present? ? content : doc.text[0..5000]
        end
      end
    rescue StandardError => e
      Rails.logger.error "Playwright 잡코리아 크롤링 실패: #{e.message}"
      return fetch_general_content(url)
    end
  end
  
  def fetch_wanted_content(url)
    # Playwright를 사용한 원티드 동적 크롤링
    Rails.logger.info "Playwright로 원티드 크롤링: #{url}"
    
    begin
      Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
        playwright.chromium.launch(headless: true) do |browser|
          page = browser.new_page
          page.goto(url, waitUntil: 'domcontentloaded')
          sleep(3) # 원티드는 로딩이 좀 더 걸림
          
          # HTML 가져오기
          html = page.content
          doc = Nokogiri::HTML(html)
          
          content = ""
          
          # 회사명
          company = doc.at('[data-test="company-name"], .company-name')&.text&.strip
          content += "회사: #{company}\n" if company
          
          # 직무명
          position = doc.at('[data-test="job-header-title"], h1')&.text&.strip
          content += "직무: #{position}\n\n" if position
          
          # 주요 업무
          main_tasks = doc.at('[data-test="job-description"], .job-description')&.text&.strip
          content += "주요 업무:\n#{main_tasks}\n" if main_tasks
          
          # 자격 요건
          requirements = doc.at('[data-test="job-requirements"]')&.text&.strip
          content += "\n자격 요건:\n#{requirements}\n" if requirements
          
          Rails.logger.info "원티드 크롤링 완료: #{content.length} 글자"
          
          return content.present? ? content : doc.text[0..5000]
        end
      end
    rescue StandardError => e
      Rails.logger.error "Playwright 원티드 크롤링 실패: #{e.message}"
      return fetch_general_content(url)
    end
  end
  
  def fetch_incruit_content(url)
    # 인크루트 특화 크롤링
    fetch_general_content(url)
  end
  
  def fetch_jobplanet_content(url)
    # 잡플래닛 특화 크롤링
    fetch_general_content(url)
  end
  
  def analyze_with_ai_direct(company_name, position, content, source_url = nil)
    prompt = build_direct_analysis_prompt(company_name, position, content, source_url)
    
    response = make_api_request(prompt)
    parse_response(response)[:content]
  end
  
  def analyze_with_ai(content, url)
    prompt = build_analysis_prompt(content, url)
    
    response = make_api_request(prompt)
    parse_response(response)[:content]
  end
  
  def build_direct_analysis_prompt(company_name, position, content, source_url = nil)
    <<~PROMPT
      당신은 채용 전문 컨설턴트입니다. 다음 채용공고를 분석하여 구직자에게 도움이 되는 인사이트를 제공해주세요.
      
      **회사명**: #{company_name}
      **지원 직무**: #{position}
      #{source_url.present? ? "**출처**: #{source_url}" : ""}
      
      **채용공고 내용**:
      #{content}
      
      다음 형식으로 상세히 분석해주세요:
      
      ## 📊 #{company_name} - #{position} 채용공고 심층 분석
      
      ### 🏢 기업 정보
      - **기업명**: #{company_name}
      - **산업 분야**: [채용공고에서 파악된 산업/업종]
      - **기업 규모**: [채용공고에서 추정되는 규모]
      - **기업 특징**: [3-5줄로 기업 특성 설명]
      
      ### 💼 직무 정보
      - **모집 직무**: #{position}
      - **직급/경력**: [채용공고에서 파악된 정보]
      - **근무 형태**: [정규직/계약직/인턴 등]
      - **근무 지역**: [채용공고에서 파악된 위치]
      - **주요 업무**: [채용공고에서 추출한 담당 업무]
      
      ### 🎯 핵심 키워드 (중요도 순)
      [채용공고에서 추출한 가장 중요한 키워드 5개와 설명]
      
      ### 💪 필수 역량
      **기술적 역량**
      [채용공고에서 요구하는 필수 기술/지식]
      
      **소프트 스킬**
      [채용공고에서 요구하는 대인관계/태도 역량]
      
      ### ⭐ 우대 사항
      [채용공고에서 명시된 우대 사항 정리]
      
      ### 🏆 기업이 원하는 인재상
      [채용공고 내용을 바탕으로 분석한 이상적인 지원자 프로필]
      
      ### 📝 자소서 작성 전략
      **강조해야 할 포인트**
      [채용공고를 바탕으로 자소서에 꼭 포함해야 할 내용]
      
      **차별화 전략**
      [다른 지원자와 차별화할 수 있는 방법]
      
      ### 💡 면접 대비 포인트
      **예상 질문**
      [채용공고를 바탕으로 예상되는 면접 질문 3개]
      
      **준비 사항**
      [면접 전 준비해야 할 사항]
      
      ### 📊 경쟁력 평가
      **지원 난이도**: [★ 1-5점]
      **경쟁률 예상**: [높음/중간/낮음]
      **추천 지원 시기**: [즉시/준비 후/경력 쌓은 후]
      
      ### 💬 종합 조언
      [채용공고를 종합적으로 분석한 조언과 지원 전략]
      
      ---
      💡 **AI 인사이트**: [이 채용공고의 숨겨진 의미나 트렌드 2줄]
    PROMPT
  end
  
  def build_analysis_prompt(content, url)
    <<~PROMPT
      당신은 채용 전문 컨설턴트입니다. 다음 채용공고를 분석하여 구직자에게 도움이 되는 인사이트를 제공해주세요.
      
      채용공고 URL: #{url}
      
      채용공고 내용:
      #{content[0..4000]} #{content.length > 4000 ? '...(이하 생략)' : ''}
      
      다음 형식으로 상세히 분석해주세요:
      
      ## 📊 채용공고 심층 분석
      
      ### 🏢 기업 정보
      - **기업명**: [기업명]
      - **산업 분야**: [산업/업종]
      - **기업 규모**: [대기업/중견/중소/스타트업]
      - **기업 특징**: [3-5줄로 기업 특성 설명]
      
      ### 💼 직무 정보
      - **모집 직무**: [구체적인 직무명]
      - **직급/경력**: [신입/경력 및 요구 연차]
      - **근무 형태**: [정규직/계약직/인턴 등]
      - **근무 지역**: [구체적인 위치]
      
      ### 🎯 핵심 키워드 (중요도 순)
      1. **[키워드1]**: [왜 중요한지 설명]
      2. **[키워드2]**: [왜 중요한지 설명]
      3. **[키워드3]**: [왜 중요한지 설명]
      4. **[키워드4]**: [왜 중요한지 설명]
      5. **[키워드5]**: [왜 중요한지 설명]
      
      ### 💪 필수 역량
      **기술적 역량**
      - [필수 기술 스택 또는 전문 지식]
      - [요구되는 도구/프로그램 활용 능력]
      - [필요한 자격증이나 인증]
      
      **소프트 스킬**
      - [의사소통, 협업 등 대인관계 역량]
      - [문제해결, 창의성 등 사고 역량]
      - [리더십, 책임감 등 태도 역량]
      
      ### ⭐ 우대 사항
      - [우대 경험 1]
      - [우대 경험 2]
      - [우대 경험 3]
      
      ### 🏆 기업이 원하는 인재상
      **핵심 가치**
      - [기업이 중요시하는 가치 1]
      - [기업이 중요시하는 가치 2]
      - [기업이 중요시하는 가치 3]
      
      **이상적인 지원자 프로필**
      [3-4줄로 이 기업이 원하는 이상적인 지원자 설명]
      
      ### 📝 자소서 작성 전략
      **강조해야 할 포인트**
      1. [자소서에 꼭 포함해야 할 내용 1]
      2. [자소서에 꼭 포함해야 할 내용 2]
      3. [자소서에 꼭 포함해야 할 내용 3]
      
      **차별화 전략**
      - [다른 지원자와 차별화할 수 있는 방법]
      - [기업 특성에 맞는 어필 전략]
      
      ### 💡 면접 대비 포인트
      **예상 질문**
      1. "[예상 질문 1]"
      2. "[예상 질문 2]"
      3. "[예상 질문 3]"
      
      **준비 사항**
      - [면접 전 꼭 조사해야 할 내용]
      - [준비해야 할 포트폴리오나 자료]
      
      ### 🎨 자소서 커스터마이징 가이드
      **지원동기 작성 팁**
      - [이 기업만의 특별한 지원동기 포인트]
      - [기업 비전과 연결할 수 있는 개인 목표]
      
      **경험 기술 팁**
      - [이 직무와 연관 지을 수 있는 경험 유형]
      - [STAR 기법으로 작성할 때 강조점]
      
      **입사 후 포부 팁**
      - [단기/중기/장기 목표 설정 가이드]
      - [기업 성장 방향과 일치시킬 포인트]
      
      ### 📊 경쟁력 평가
      **지원 난이도**: [★★★★★ 5점 만점]
      **경쟁률 예상**: [높음/중간/낮음]
      **추천 지원 시기**: [즉시/준비 후/경력 쌓은 후]
      
      ### 💬 종합 조언
      [5-7줄로 이 채용공고에 대한 종합적인 조언과 지원 전략 제시]
      
      ---
      💡 **AI 인사이트**: [이 채용공고의 숨겨진 의미나 트렌드 2줄]
    PROMPT
  end
  
  def make_api_request(prompt)
    uri = URI(OPENAI_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      model: @model,
      messages: [
        {
          role: 'system',
          content: '당신은 한국 채용 시장에 정통한 HR 전문가입니다. 채용공고를 분석하여 구직자에게 실질적인 도움이 되는 인사이트를 제공합니다.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.7,
      max_tokens: 4000
    }.to_json
    
    response = http.request(request)
    JSON.parse(response.body)
  end
  
  def parse_response(response)
    if response['error']
      { error: response['error']['message'] }
    elsif response['choices'] && response['choices'].first
      {
        success: true,
        content: response['choices'].first['message']['content'],
        usage: response['usage']
      }
    else
      { error: '예상치 못한 응답 형식입니다' }
    end
  end
end