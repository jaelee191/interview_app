# 온톨로지 분석 시뮬레이션 스크립트

puts "="*50
puts "온톨로지 분석 시뮬레이션 시작"
puts "="*50

# 1. 테스트 사용자 생성
puts "\n1. 테스트 사용자 생성 중..."
user = User.find_or_create_by(email: "test@example.com") do |u|
  u.password = "password123"
end
puts "✅ 사용자 생성 완료: #{user.email}"

# 2. 사용자 프로필 생성
puts "\n2. 사용자 프로필 생성 중..."
profile = user.user_profile || user.create_user_profile(
  name: "김철수",
  email: "test@example.com",
  phone: "010-1234-5678",
  education: "서울대학교 컴퓨터공학과 졸업",
  career_history: [
    {
      "id" => SecureRandom.uuid,
      "company" => "네이버",
      "position" => "백엔드 개발자",
      "duration" => "2020.03 - 2022.12",
      "achievements" => "대용량 트래픽 처리 시스템 구축, MSA 아키텍처 도입"
    },
    {
      "id" => SecureRandom.uuid,
      "company" => "카카오",
      "position" => "시니어 백엔드 개발자",
      "duration" => "2023.01 - 현재",
      "achievements" => "실시간 메시징 서비스 개발, DevOps 파이프라인 구축"
    }
  ],
  projects: [
    {
      "id" => SecureRandom.uuid,
      "name" => "실시간 채팅 시스템",
      "role" => "백엔드 리드",
      "duration" => "6개월",
      "description" => "WebSocket 기반 실시간 채팅 시스템 설계 및 구현",
      "tech_stack" => "Node.js, Redis, MongoDB, Docker"
    },
    {
      "id" => SecureRandom.uuid,
      "name" => "AI 추천 시스템",
      "role" => "ML 엔지니어",
      "duration" => "4개월",
      "description" => "사용자 행동 기반 개인화 추천 알고리즘 개발",
      "tech_stack" => "Python, TensorFlow, Kubernetes"
    }
  ],
  technical_skills: ["Java", "Python", "Spring Boot", "AWS", "Kubernetes", "React", "PostgreSQL", "Redis"],
  achievements: "정보처리기사, AWS Solutions Architect, 오픈소스 컨트리뷰터"
)
puts "✅ 프로필 생성 완료: #{profile.name}"

# 3. 채용공고 분석 데이터 생성
puts "\n3. 채용공고 데이터 생성 중..."
job_analysis = JobAnalysis.find_or_create_by(
  url: "https://example.com/job/123"
) do |j|
  j.company_name = "토스"
  j.position = "백엔드 개발자"
  j.keywords = ["Java", "Spring", "MSA", "대용량 트래픽", "결제 시스템", "금융"]
  j.required_skills = ["Java", "Spring Boot", "MySQL", "AWS", "Kubernetes", "MSA 설계"]
  j.company_values = ["도전", "혁신", "사용자 중심", "빠른 실행"]
  j.summary = "토스 결제 플랫폼 백엔드 개발자를 모집합니다. 대용량 트래픽 처리 경험과 금융 도메인 이해도가 있는 분을 찾습니다."
  j.analysis_result = {
    "requirements" => "3년 이상 경력, Java/Spring 전문가, MSA 설계 경험",
    "preferred" => "금융 도메인 경험, 결제 시스템 개발 경험",
    "culture" => "빠른 의사결정, 도전적인 문화, 사용자 중심 사고"
  }.to_json
end
puts "✅ 채용공고 생성 완료: #{job_analysis.company_name} - #{job_analysis.position}"

# 4. 온톨로지 분석 실행
puts "\n4. 온톨로지 분석 실행 중..."
puts "-"*30

begin
  service = UnifiedOntologyService.new(job_analysis.id, profile.id)
  result = service.perform_analysis
  
  puts "\n📊 분석 결과:"
  puts "-"*30
  puts "Result: #{result.inspect}"
  
  if result && result.respond_to?(:matching_result)
    matching = result.matching_result
    
    puts "\n✨ 종합 매칭 점수: #{matching['overall_score']}%"
    
    puts "\n📈 세부 점수:"
    puts "  - 기술 매칭도: #{matching['technical_match']}%"
    puts "  - 경험 매칭도: #{matching['experience_match']}%"
    puts "  - 문화 적합도: #{matching['culture_fit']}%"
    
    puts "\n💪 강점:"
    (matching['strengths'] || []).each_with_index do |strength, i|
      puts "  #{i+1}. #{strength}"
    end
    
    puts "\n⚠️ 보완 필요사항:"
    (matching['gaps'] || []).each_with_index do |gap, i|
      puts "  #{i+1}. #{gap}"
    end
    
    puts "\n💡 추천 전략:"
    (matching['recommendations'] || []).each_with_index do |rec, i|
      puts "  #{i+1}. #{rec}"
    end
    
    # 시각화 데이터 생성
    viz_data = service.generate_visualization_data(matching)
    puts "\n📊 시각화 데이터 생성 완료:"
    puts "  - 노드 수: #{viz_data[:nodes].size}"
    puts "  - 연결 수: #{viz_data[:links].size}"
    
    puts "\n✅ 온톨로지 분석 성공!"
  else
    puts "❌ 분석 결과를 생성하지 못했습니다."
  end
  
rescue => e
  puts "❌ 오류 발생: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

puts "\n" + "="*50
puts "시뮬레이션 완료"
puts "="*50