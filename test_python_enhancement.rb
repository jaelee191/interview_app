#!/usr/bin/env ruby
require_relative 'config/environment'

# Python 서비스 테스트
service = PythonAnalysisService.new

test_text = "저는 저의 경험을 통해 많은 것을 배웠다고 생각합니다. 또한 여러 프로젝트를 진행하면서 문제해결 능력을 키웠습니다."
company = "삼성"

puts "테스트 텍스트:"
puts test_text
puts "\n회사: #{company}"
puts "\n" + "="*50

result = service.enhance_rewrite(test_text, company)

if result[:success]
  puts "\n✅ Python 향상 성공!"
  puts "\n향상된 텍스트:"
  puts result[:data]["enhanced_text"]
  
  puts "\n📊 개선 지표:"
  improvements = result[:data]["improvements"]
  puts "- 가독성 변화: #{improvements["readability_change"]}"
  puts "- AI 자연스러움: #{improvements["ai_naturalness"]}%"
  puts "- 키워드 최적화: #{improvements["keyword_optimization"]}%"
  puts "- STAR 구조: #{improvements["structure_score"]}%"
  
  puts "\n💡 제안사항:"
  result[:data]["suggestions"].each do |suggestion|
    puts "- #{suggestion}"
  end
else
  puts "\n❌ 오류 발생: #{result[:error]}"
end