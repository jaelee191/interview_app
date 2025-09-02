#!/usr/bin/env ruby
require_relative 'config/environment'

# 작은 테스트 텍스트
test_content = <<~TEXT
저는 고객 중심 마케팅 전문가로서 30번의 대외활동과 5년간의 아르바이트 경험을 통해 
실무 역량을 키워왔습니다. 특히 링커리어 에디터 활동 중 커뮤니티를 200% 활성화시킨 
경험이 있으며, IT 기업 인턴십에서 홈페이지 방문자를 4배 증가시킨 성과를 달성했습니다.
TEXT

puts "수정된 프롬프트 테스트 시작..."
puts "=" * 60

service = AdvancedCoverLetterService.new

# 개선점 섹션만 테스트
puts "\n📝 개선점 분석 테스트..."
result = service.analyze_improvements(test_content)

if result
  puts "\n결과 확인:"
  puts "-" * 40
  
  # 프롬프트 명령어가 포함되어 있는지 확인
  problematic_patterns = [
    /\[1문단.*?\]/,
    /\[2문단.*?\]/,
    /\[3문단.*?\]/,
    /\[4문단.*?\]/,
    /\[동일한.*?구조.*?\]/,
    /\[첫 번째 문단.*?\]/,
    /\[두 번째 문단.*?\]/,
    /\[세 번째 문단.*?\]/
  ]
  
  found_issues = []
  problematic_patterns.each do |pattern|
    if result =~ pattern
      found_issues << result[pattern]
    end
  end
  
  if found_issues.empty?
    puts "✅ 프롬프트 명령어가 출력되지 않음 (성공!)"
  else
    puts "❌ 프롬프트 명령어가 발견됨:"
    found_issues.each { |issue| puts "   - #{issue}" }
  end
  
  # 개선점 형식 확인
  improvement_count = result.scan(/### 개선점 \d+:/).length
  puts "\n개선점 개수: #{improvement_count}개"
  
  # 첫 번째 개선점 일부 출력
  first_improvement = result[/### 개선점 1:.*?(?=### 개선점 2:|$)/m]
  if first_improvement
    puts "\n첫 번째 개선점 샘플 (200자):"
    puts first_improvement[0..200] + "..."
  end
else
  puts "분석 실패"
end