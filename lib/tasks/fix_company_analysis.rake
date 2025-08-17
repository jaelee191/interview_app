namespace :company do
  desc "Fix incorrect company analysis data"
  task fix_analysis: :environment do
    puts "🔧 Starting company analysis data fix..."
    
    # 럭셔리앤하우스 분석 수정
    luxury_analysis = CompanyAnalysis.find_by(id: 9)
    
    if luxury_analysis
      puts "Found analysis for: #{luxury_analysis.company_name}"
      
      # 정확한 정보로 업데이트
      accurate_data = {
        industry: "부동산 중개업",
        company_size: "중소기업",
        recent_issues: <<~TEXT,
          ## 기업 개요
          
          럭셔리앤하우스부동산중개법인은 2013년 설립된 고급 주거 전문 부동산 중개 회사입니다.
          
          **기본 정보:**
          - 설립: 2013년
          - 직원수: 50명
          - 위치: 서울 서초구 방배동
          - 주요 사업: 20억~300억 고급빌라, 고급주택, 타운하우스 중개
          
          **조직 구성:**
          - 전문컨설팅영업팀
          - 마케팅팀
          - 웹관리부
          - 빌딩관리부(퍼스트빌딩)
          - 영상팀
        TEXT
        business_context: <<~TEXT,
          ## 비즈니스 특징
          
          럭셔리앤하우스는 단순한 부동산 중개를 넘어 "품격과 기품있는 삶"을 제공한다는 철학으로 운영됩니다.
          
          **핵심 경쟁력:**
          - 방배동 기반 로컬 전문성
          - 고급 주거 시장 특화
          - 고객 맞춤형 컨시어지 서비스
          - 네트워크 기반 프리미엄 매물 확보
          
          **타겟 고객:**
          - 고소득 전문직
          - 기업 임원
          - 해외 거주 귀국자
          - 프리미엄 주거 선호 고객
        TEXT
        hiring_patterns: <<~TEXT,
          ## 채용 정보
          
          **채용 특징:**
          - 경력무관, 학력무관
          - 급여: 3,000~20,000만원 (성과급 체계)
          - 정규직 채용
          
          **주요 직무:**
          - 고급주거 컨설턴트
          - 부동산 마케팅
          - 고객 관리
          
          **인재상:**
          - 고객 커뮤니케이션 능력
          - 네트워킹 역량
          - 서비스 마인드
          - 부동산 시장 이해
        TEXT
        competitor_info: <<~TEXT,
          ## 경쟁 환경
          
          **시장 포지션:**
          - 방배동 일대 고급 주거 중개 선도
          - 중소규모이나 프리미엄 포지셔닝 성공
          
          **차별화 요소:**
          - 로컬 네트워크 강점
          - 고객 신뢰 기반 운영
          - 맞춤형 서비스 제공
        TEXT
        industry_trends: <<~TEXT,
          ## 향후 전망
          
          **성장 전략:**
          - 고급 주거 시장 집중
          - 고객 관계 관리 강화
          - 디지털 마케팅 확대
          
          **조직 문화:**
          - 2024년 제주도 리더 워크샵
          - 정기 시상식 운영
          - 팀워크 중시 문화
        TEXT
        metadata: {
          verified: true,
          company_scale: :small,
          actual_employee_count: 50,
          founded_year: 2013,
          location: "서울 서초구 방배동",
          analysis_type: 'corrected',
          corrected_at: Time.current
        }
      }
      
      luxury_analysis.update!(accurate_data)
      puts "✅ Successfully updated analysis for #{luxury_analysis.company_name}"
      
      # 검증 정보 추가
      puts "\n📊 Updated Information:"
      puts "- Industry: #{luxury_analysis.industry}"
      puts "- Company Size: #{luxury_analysis.company_size}"
      puts "- Metadata: #{luxury_analysis.metadata}"
      
    else
      puts "❌ Analysis ID 9 not found"
    end
    
    puts "\n✨ Fix completed!"
  end
  
  desc "Verify company analysis with web data"
  task verify_analysis: :environment do
    company_name = ENV['COMPANY'] || "럭셔리앤하우스부동산중개법인"
    
    puts "🔍 Verifying analysis for: #{company_name}"
    
    service = VerifiedCompanyAnalysisService.new
    result = service.analyze_with_verification(company_name)
    
    if result[:success]
      puts "✅ Verification successful!"
      puts "\nCompany Scale: #{result[:company_scale]}"
      puts "\nWeb Data:"
      puts result[:web_data].to_yaml
      puts "\nAnalysis Preview:"
      puts result[:analysis][0..500]
    else
      puts "❌ Verification failed: #{result[:error]}"
    end
  end
end