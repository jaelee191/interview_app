#!/usr/bin/env ruby
# 분석 결과 확인 스크립트
require_relative 'config/environment'

puts "=" * 60
puts "분석 결과 확인"
puts "=" * 60

# 가장 최근 자소서 확인
latest_cover_letter = CoverLetter.last

if latest_cover_letter
  puts "📄 최근 자소서 ID: #{latest_cover_letter.id}"
  puts "📅 생성일: #{latest_cover_letter.created_at}"
  puts "📝 내용 길이: #{latest_cover_letter.content&.length || 0}자"

  if latest_cover_letter.analysis_result.present?
    puts "✅ 분석 결과 있음!"
    puts "📊 분석 결과 길이: #{latest_cover_letter.analysis_result.length}자"

    # JSON 파싱 시도
    begin
      json_result = JSON.parse(latest_cover_letter.analysis_result)
      puts "🔧 JSON 파싱 성공!"

      if json_result['sections']
        puts "\n📋 섹션별 항목 수:"
        json_result['sections'].each do |section|
          items_count = section['items']&.length || 0
          puts "  #{section['number']}. #{section['title']}: #{items_count}개 항목"

          if items_count > 0
            puts "     항목 제목들:"
            section['items'].each do |item|
              puts "       #{item['number']}. #{item['title']}"
            end
          end
        end
      end

    rescue JSON::ParserError => e
      puts "❌ JSON 파싱 실패: #{e.message}"
      puts "📄 원본 분석 결과 (처음 500자):"
      puts latest_cover_letter.analysis_result[0..500]
    end

  else
    puts "⏳ 분석 결과 없음 (아직 분석 중이거나 실패)"
  end

else
  puts "❌ 자소서가 없습니다."
end

puts "\n" + "=" * 60
puts "확인 완료!"
puts "=" * 60


