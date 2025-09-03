#!/usr/bin/env ruby
# ID 58번 자소서 분석 결과 확인
require_relative 'config/environment'

puts "=" * 80
puts "ID 58번 자소서 분석 결과 확인"
puts "=" * 80

# ID 58번 자소서 조회
cover_letter = CoverLetter.find(58)

puts "📄 자소서 정보:"
puts "  ID: #{cover_letter.id}"
puts "  생성일: #{cover_letter.created_at}"
puts "  업데이트일: #{cover_letter.updated_at}"
puts "  내용 길이: #{cover_letter.content&.length || 0}자"

puts "\n" + "=" * 80
puts "📝 업로드된 PDF에서 추출된 원문 내용"
puts "=" * 80
puts cover_letter.content
puts "\n" + "=" * 80

if cover_letter.analysis_result.present?
  puts "✅ 분석 결과 있음!"
  puts "📊 분석 결과 길이: #{cover_letter.analysis_result.length}자"

  puts "\n" + "=" * 80
  puts "🔍 원본 분석 결과 (처음 1000자)"
  puts "=" * 80
  puts cover_letter.analysis_result[0..1000]
  puts "\n" + "=" * 80

  # JSON 파싱 시도
  begin
    json_result = JSON.parse(cover_letter.analysis_result)
    puts "🔧 JSON 파싱 성공!"

    puts "\n" + "=" * 80
    puts "📋 파싱된 JSON 구조"
    puts "=" * 80

    if json_result['sections']
      puts "📊 총 #{json_result['sections'].length}개 섹션 발견:"

      json_result['sections'].each do |section|
        puts "\n🔹 섹션 #{section['number']}: #{section['title']}"
        puts "   항목 수: #{section['items']&.length || 0}개"

        if section['items'] && section['items'].length > 0
          section['items'].each do |item|
            puts "     #{item['number']}. #{item['title']}"
            puts "        내용 길이: #{item['content']&.length || 0}자"
            if item['content'] && item['content'].length > 100
              puts "        내용 미리보기: #{item['content'][0..100]}..."
            else
              puts "        내용: #{item['content']}"
            end
          end
        end
      end
    end

    # 파싱된 결과와 원본 비교
    puts "\n" + "=" * 80
    puts "🔍 파싱 검증 결과"
    puts "=" * 80

    # 원본에서 섹션 제목들 추출
    original_sections = cover_letter.analysis_result.scan(/###\s*\d+\.\s*\*\*([^*]+)\*\*/)
    parsed_sections = json_result['sections']&.map { |s| s['title'] } || []

    puts "원본에서 발견된 섹션 제목들:"
    original_sections.each_with_index do |title, i|
      puts "  #{i+1}. #{title[0]}"
    end

    puts "\n파싱된 섹션 제목들:"
    parsed_sections.each_with_index do |title, i|
      puts "  #{i+1}. #{title}"
    end

    # 일치 여부 확인
    if original_sections.length == parsed_sections.length
      puts "\n✅ 섹션 수 일치: #{original_sections.length}개"

      mismatches = []
      original_sections.each_with_index do |original, i|
        if parsed_sections[i] != original[0]
          mismatches << { index: i+1, original: original[0], parsed: parsed_sections[i] }
        end
      end

      if mismatches.empty?
        puts "✅ 모든 섹션 제목이 정확히 파싱됨!"
      else
        puts "❌ 파싱 불일치 발견:"
        mismatches.each do |mismatch|
          puts "  섹션 #{mismatch[:index]}: 원본='#{mismatch[:original]}' vs 파싱='#{mismatch[:parsed]}'"
        end
      end
    else
      puts "❌ 섹션 수 불일치: 원본 #{original_sections.length}개 vs 파싱 #{parsed_sections.length}개"
    end

  rescue JSON::ParserError => e
    puts "❌ JSON 파싱 실패: #{e.message}"
    puts "원본 분석 결과 (처음 500자):"
    puts cover_letter.analysis_result[0..500]
  end

else
  puts "⏳ 분석 결과 없음 (아직 분석 중이거나 실패)"
end

puts "\n" + "=" * 80
puts "확인 완료!"
puts "=" * 80


