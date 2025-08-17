#!/usr/bin/env ruby
require_relative 'config/environment'
require 'benchmark'

puts "=" * 60
puts "API 병렬처리 성능 테스트"
puts "=" * 60

# 테스트용 자소서
test_content = <<~CONTENT
  고객 니즈를 발굴하고 브랜드를 각인시키는 마케터가 되고 싶습니다.
  다양한 마케팅 경험을 통해 데이터 기반 의사결정 능력을 키웠습니다.
CONTENT

service = ParallelAnalysisService.new

puts "\n📊 성능 비교 테스트"
puts "-" * 40

# 1. Thread 기반 병렬처리
puts "\n1️⃣ Thread 기반 병렬처리"
time_threads = Benchmark.realtime do
  result = service.analyze_with_threads(test_content)
  if result[:success]
    puts "✅ 성공"
  else
    puts "❌ 실패: #{result[:errors]}"
  end
end
puts "소요 시간: #{time_threads.round(2)}초"

# 2. Concurrent Ruby (젬 설치 필요)
puts "\n2️⃣ Concurrent Ruby"
begin
  require 'concurrent'
  time_concurrent = Benchmark.realtime do
    result = service.analyze_with_concurrent(test_content)
    if result[:success]
      puts "✅ 성공"
    else
      puts "❌ 실패: #{result[:errors]}"
    end
  end
  puts "소요 시간: #{time_concurrent.round(2)}초"
rescue LoadError
  puts "⚠️  concurrent-ruby 젬이 설치되지 않음"
  puts "설치: gem install concurrent-ruby"
end

# 3. Parallel 젬 (젬 설치 필요)
puts "\n3️⃣ Parallel 젬"
begin
  require 'parallel'
  time_parallel = Benchmark.realtime do
    result = service.analyze_with_parallel_gem(test_content)
    if result[:success]
      puts "✅ 성공"
    else
      puts "❌ 실패"
    end
  end
  puts "소요 시간: #{time_parallel.round(2)}초"
rescue LoadError
  puts "⚠️  parallel 젬이 설치되지 않음"
  puts "설치: gem install parallel"
end

# 순차 처리와 비교
puts "\n4️⃣ 순차 처리 (비교용)"
time_sequential = Benchmark.realtime do
  service_seq = AdvancedCoverLetterService.new
  result = service_seq.analyze_cover_letter_only(test_content)
  if result[:success]
    puts "✅ 성공"
  else
    puts "❌ 실패"
  end
end
puts "소요 시간: #{time_sequential.round(2)}초"

puts "\n" + "=" * 60
puts "📈 성능 개선 요약"
puts "=" * 60
puts "순차 처리: #{time_sequential.round(2)}초"
puts "Thread 병렬: #{time_threads.round(2)}초 (#{((1 - time_threads/time_sequential) * 100).round(1)}% 개선)"
puts "=" * 60