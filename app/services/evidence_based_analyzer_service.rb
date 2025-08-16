class EvidenceBasedAnalyzerService
  def initialize(company_name, position)
    @company_name = company_name
    @position = position
    @evidence_levels = {
      confirmed: [],      # 뉴스, 공시 등 확인된 사실
      inferred: [],       # 논리적 추론
      assumed: [],        # 가정 사항
      unknown: []         # 확인 필요 사항
    }
  end
  
  def analyze_with_evidence
    {
      confirmed_facts: gather_confirmed_facts,
      logical_inferences: make_logical_inferences,
      assumptions: list_assumptions,
      unknowns: identify_unknowns,
      confidence_score: calculate_confidence
    }
  end
  
  private
  
  def gather_confirmed_facts
    facts = []
    
    # 1. 뉴스 크롤링
    news_data = crawl_recent_news
    news_data.each do |news|
      facts << {
        fact: news[:title],
        source: news[:source],
        date: news[:date],
        url: news[:url],
        confidence: 1.0  # 100% 확신
      }
    end
    
    # 2. 공시 정보
    disclosure_data = fetch_disclosure_data
    disclosure_data.each do |disclosure|
      facts << {
        fact: disclosure[:content],
        source: "공시",
        date: disclosure[:date],
        confidence: 1.0
      }
    end
    
    # 3. 공식 발표
    official_announcements = fetch_official_announcements
    
    @evidence_levels[:confirmed] = facts
    facts
  end
  
  def make_logical_inferences
    inferences = []
    
    # 확인된 사실로부터 추론
    @evidence_levels[:confirmed].each do |fact|
      # 예: "하반기 시설 가동" → "엔지니어 채용 필요"
      if fact[:fact].include?("시설") && fact[:fact].include?("가동")
        inferences << {
          inference: "신규 시설 운영을 위한 엔지니어 수요 예상",
          based_on: fact[:fact],
          confidence: 0.8  # 80% 확신
        }
      end
      
      # 예: "5조원 투자" → "대규모 채용"
      if fact[:fact].match?(/\d+조.*투자/)
        inferences << {
          inference: "대규모 투자에 따른 인력 확충 예상",
          based_on: fact[:fact],
          confidence: 0.7
        }
      end
    end
    
    @evidence_levels[:inferred] = inferences
    inferences
  end
  
  def list_assumptions
    # 명시적으로 가정한 내용 표시
    assumptions = []
    
    if @evidence_levels[:confirmed].none? { |f| f[:fact].include?("채용") }
      assumptions << {
        assumption: "채용이 진행 중일 것으로 가정",
        reason: "신규 시설에는 일반적으로 인력이 필요",
        confidence: 0.5
      }
    end
    
    @evidence_levels[:assumed] = assumptions
    assumptions
  end
  
  def identify_unknowns
    # 확인이 필요한 사항
    unknowns = [
      {
        question: "정확한 시설 가동 시점은?",
        how_to_verify: "SK이노베이션 공식 채용 페이지 확인",
        importance: "high"
      },
      {
        question: "#{@position} 실제 채용 공고가 있는가?",
        how_to_verify: "채용 사이트 검색",
        importance: "critical"
      },
      {
        question: "필요 인원 규모는?",
        how_to_verify: "IR 자료 또는 뉴스 확인",
        importance: "medium"
      }
    ]
    
    @evidence_levels[:unknown] = unknowns
    unknowns
  end
  
  def calculate_confidence
    # 전체 분석의 신뢰도 계산
    total_items = @evidence_levels.values.flatten.size
    confirmed_items = @evidence_levels[:confirmed].size
    
    if total_items > 0
      base_confidence = (confirmed_items.to_f / total_items) * 100
      
      # 추론과 가정이 많을수록 신뢰도 감소
      inference_penalty = @evidence_levels[:inferred].size * 2
      assumption_penalty = @evidence_levels[:assumed].size * 5
      
      [base_confidence - inference_penalty - assumption_penalty, 0].max.round(1)
    else
      0
    end
  end
  
  def crawl_recent_news
    # 실제 뉴스 크롤링
    company = Company.find_or_create_by(name: @company_name)
    crawler = CompanyNewsCrawlerService.new(company)
    
    news = crawler.crawl_all_sources
    news.map do |item|
      {
        title: item[:title],
        source: item[:source],
        date: item[:published_at],
        url: item[:url]
      }
    end.first(5)  # 최근 5개만
  rescue => e
    Rails.logger.error "News crawling failed: #{e.message}"
    []
  end
  
  def fetch_disclosure_data
    # 공시 정보 수집 (DART API 등)
    []  # 실제 구현 필요
  end
  
  def fetch_official_announcements
    # 기업 공식 발표 수집
    []  # 실제 구현 필요
  end
end