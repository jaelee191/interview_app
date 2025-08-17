#!/usr/bin/env ruby
# 자소서 분석 최적화 테스트 스크립트
require_relative 'config/environment'

puts "=" * 60
puts "자소서 분석 최적화 테스트"
puts "=" * 60

# 테스트용 자소서 내용
test_content = <<~CONTENT
  안녕하세요. 저는 소프트웨어 개발자 지원자입니다.
  
  대학에서 컴퓨터공학을 전공하며 프로그래밍에 대한 열정을 키웠습니다.
  다양한 프로젝트 경험을 통해 문제 해결 능력을 기르고, 
  팀워크의 중요성을 배웠습니다.
  
  특히 최근 진행한 웹 애플리케이션 개발 프로젝트에서는
  프론트엔드와 백엔드를 모두 담당하며 풀스택 개발 역량을 쌓았습니다.
  
  귀사에서 성장하고 기여할 수 있는 개발자가 되고 싶습니다.
CONTENT

service = AdvancedCoverLetterService.new

puts "\n1. 자소서 분석만 실행 (기업 분석 제외)"
puts "-" * 40

start_time = Time.now
result = service.analyze_cover_letter_only(test_content)
end_time = Time.now

if result[:success]
  puts "✅ 분석 성공!"
  puts "소요 시간: #{(end_time - start_time).round(2)}초"
  puts "\n분석 결과 미리보기:"
  puts result[:full_analysis][0..500] + "..."
else
  puts "❌ 분석 실패: #{result[:error]}"
end

puts "\n" + "=" * 60
puts "2. 피드백 기반 리라이트 테스트"
puts "-" * 40

if result[:success] && result[:analysis]
  start_time = Time.now
  rewrite_result = service.rewrite_with_feedback_only(
    test_content,
    result[:analysis],
    "테스트기업",
    "소프트웨어 개발자"
  )
  end_time = Time.now
  
  if rewrite_result[:success]
    puts "✅ 리라이트 성공!"
    puts "소요 시간: #{(end_time - start_time).round(2)}초"
    puts "\n리라이트된 내용 미리보기:"
    puts rewrite_result[:rewritten_letter][0..500] + "..."
  else
    puts "❌ 리라이트 실패: #{rewrite_result[:error]}"
  end
end

puts "\n" + "=" * 60
puts "테스트 완료!"
puts "=" * 60