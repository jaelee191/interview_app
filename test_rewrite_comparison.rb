#!/usr/bin/env ruby
require_relative 'config/environment'

# 테스트용 자소서 샘플
test_content = <<~CONTENT
저는 대학교에서 컴퓨터공학을 전공하면서 다양한 프로젝트를 경험했습니다. 
특히 3학년 때 참여한 스타트업 인턴십에서 실제 서비스 개발을 경험하면서 
개발자로서의 역량을 키울 수 있었습니다.

인턴십 기간 동안 React와 Node.js를 활용한 웹 애플리케이션 개발을 담당했고,
사용자 피드백을 반영하여 UI/UX를 개선하는 작업을 진행했습니다.
이 과정에서 단순히 코드를 작성하는 것이 아니라 사용자 관점에서 
서비스를 바라보는 시각을 기를 수 있었습니다.

또한 팀 프로젝트를 진행하면서 협업의 중요성을 깨달았습니다.
Git을 활용한 버전 관리와 코드 리뷰 문화를 경험하면서
더 나은 코드를 작성하기 위해 노력했습니다.
CONTENT

# 피드백 분석 결과 (2단계 분석 시뮬레이션)
feedback_analysis = <<~FEEDBACK
## 2. 잘 쓴 부분 (강점 5개)
- 실무 경험(인턴십)을 구체적으로 언급
- 기술 스택(React, Node.js) 명시
- 사용자 관점의 개발 철학 표현
- 협업 경험과 도구 활용 언급
- 성장 과정이 자연스럽게 드러남

## 3. 개선이 필요한 부분
- 구체적인 성과나 수치가 없음
- 프로젝트의 규모나 영향력 불명확
- 문제 해결 과정이 추상적
- 회사에 대한 지원 동기 부재
- STAR 구조로 정리되지 않음
FEEDBACK

puts "=" * 80
puts "자소서 리라이트 비교 테스트"
puts "=" * 80
puts "\n📝 원본 자소서:"
puts "-" * 40
puts test_content
puts "\n"

service = AdvancedCoverLetterService.new

# 1. 기존 리라이트 (Python 미적용)
puts "🔄 기존 리라이트 방식 (GPT만 사용):"
puts "-" * 40
begin
  basic_result = service.rewrite_with_feedback_only(
    test_content, 
    feedback_analysis,
    "삼성전자",
    "소프트웨어 개발자"
  )
  
  if basic_result[:success]
    puts basic_result[:rewritten_letter]
    puts "\n✅ 기존 방식 완료"
  else
    puts "❌ 오류: #{basic_result[:error]}"
  end
rescue => e
  puts "❌ 기존 리라이트 오류: #{e.message}"
end

puts "\n" + "=" * 80
puts "\n🐍 Python 향상 기능이 적용된 리라이트:"
puts "-" * 40

# 2. Python 향상 적용 리라이트
begin
  enhanced_result = service.rewrite_with_python_enhancement(
    test_content,
    feedback_analysis,
    "삼성전자",
    "소프트웨어 개발자"
  )
  
  if enhanced_result[:success]
    puts enhanced_result[:rewritten_letter]
    
    puts "\n📊 Python 분석 지표:"
    puts "-" * 40
    
    if enhanced_result[:metrics]
      improvements = enhanced_result[:metrics]
      puts "✨ 개선 지표:"
      puts "  - 가독성 변화: #{improvements['readability_change']&.round(1) || 'N/A'}"
      puts "  - AI 자연스러움: #{improvements['ai_naturalness'] || 'N/A'}%"
      puts "  - 키워드 최적화: #{improvements['keyword_optimization'] || 'N/A'}%"
      puts "  - STAR 구조: #{improvements['structure_score'] || 'N/A'}%"
    end
    
    if enhanced_result[:after_metrics]
      after = enhanced_result[:after_metrics]
      puts "\n📈 향상 후 지표:"
      puts "  - 가독성 점수: #{after['readability']['score'] rescue 'N/A'}/100"
      puts "  - AI 패턴 제거: #{after['ai_patterns_removed'] || 0}개"
      puts "  - 키워드 추가: #{after['keywords_added'] || 0}개"
      puts "  - 문장 수: #{after['sentences'] || 'N/A'}개"
    end
    
    if enhanced_result[:suggestions]
      puts "\n💡 추가 개선 제안:"
      enhanced_result[:suggestions].each do |suggestion|
        puts "  - #{suggestion}"
      end
    end
    
    puts "\n✅ Python 향상 완료"
  else
    puts "❌ 오류: #{enhanced_result[:error]}"
  end
rescue => e
  puts "❌ Python 향상 오류: #{e.message}"
  puts e.backtrace.first(3).join("\n")
end

puts "\n" + "=" * 80
puts "📊 비교 요약:"
puts "-" * 40
puts "1. 기존 방식: GPT API만 사용한 텍스트 생성"
puts "   - 장점: 빠른 생성, 자연스러운 문장"
puts "   - 단점: 측정 불가능, AI 티가 남을 수 있음"
puts "\n2. Python 향상: GPT + NLP 분석 + 후처리"
puts "   - 장점: 측정 가능한 개선, AI 패턴 제거, 기업 맞춤 키워드"
puts "   - 단점: 처리 시간 증가 (약 2-3초)"
puts "\n3. 주요 차이점:"
puts "   - Python은 KoNLPy로 정확한 형태소 분석"
puts "   - 가독성 점수로 품질 측정 가능"
puts "   - AI 특유 표현 자동 제거"
puts "   - 기업별 맞춤 키워드 자동 삽입"
puts "=" * 80