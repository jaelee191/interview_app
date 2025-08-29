#!/usr/bin/env ruby
require_relative 'config/environment'

# 테스트용 자소서
test_content = <<~CONTENT
대학교 3학년 때 스타트업에서 인턴십을 하면서 웹 개발을 경험했습니다.
React와 Node.js를 사용하여 실제 서비스를 개발했고,
사용자 피드백을 반영하여 UI/UX를 개선하는 작업을 진행했습니다.
이 과정에서 사용자 관점에서 서비스를 바라보는 시각을 기를 수 있었습니다.
CONTENT

feedback = "강점: 실무 경험, 기술 스택 명시 / 개선: 구체적 성과 부재, STAR 구조 미흡"

puts "=" * 80
puts "최적화된 리라이트 테스트 (GPT → Python 후처리)"
puts "=" * 80
puts "\n📝 원본 자소서:"
puts test_content

service = AdvancedCoverLetterService.new

# 최적화된 리라이트 실행
result = service.rewrite_with_python_enhancement(
  test_content,
  feedback,
  "삼성전자",
  "소프트웨어 개발자"
)

if result[:success]
  puts "\n✅ 리라이트 성공!"
  puts "\n📄 최종 리라이트 결과:"
  puts "-" * 40
  puts result[:rewritten_letter][0..500] + "..." # 첫 500자만 표시
  
  puts "\n📊 품질 분석 지표:"
  puts "-" * 40
  
  if result[:metrics]
    puts "개선 지표:"
    puts "  • 가독성: #{result[:metrics]['readability_change']}"
    puts "  • AI 자연스러움: #{result[:metrics]['ai_naturalness']}%"
    puts "  • 키워드 최적화: #{result[:metrics]['keyword_optimization']}%"
    puts "  • STAR 구조: #{result[:metrics]['structure_score']}%"
  end
  
  if result[:after_metrics]
    puts "\n분석 결과:"
    puts "  • 가독성 점수: #{result[:after_metrics]['readability']['score']}/100"
    puts "  • 문장 수: #{result[:after_metrics]['sentences']}"
    puts "  • AI 패턴 감지: #{result[:ai_patterns_detected] || 0}개"
  end
  
  if result[:suggestions]
    puts "\n💡 개선 제안:"
    result[:suggestions].each do |suggestion|
      puts "  • #{suggestion}"
    end
  end
  
  puts "\n🔄 처리 방식: #{result[:optimization_type]}"
  
else
  puts "\n❌ 오류 발생: #{result[:error]}"
end

puts "\n" + "=" * 80
puts "테스트 완료"
puts "=" * 80