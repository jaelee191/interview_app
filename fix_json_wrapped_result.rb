#!/usr/bin/env ruby
require_relative 'config/environment'

cl = CoverLetter.find(62)

puts "Cover Letter #{cl.id} 분석 결과 수정"
puts "=" * 60

if cl.analysis_result && cl.analysis_result.start_with?('{text:')
  puts "❌ 잘못된 형식 발견: JSON 문자열로 래핑됨"
  
  # {text: "..."} 형식에서 실제 텍스트 추출
  # 정규식으로 추출
  if cl.analysis_result =~ /\{text:\s*"(.*)"\}/m
    actual_text = $1
    
    # 이스케이프 처리
    actual_text = actual_text.gsub('\\n', "\n")
    actual_text = actual_text.gsub('\\"', '"')
    actual_text = actual_text.gsub('\\\\', '\\')
    
    puts "\n✅ 실제 텍스트 추출 성공"
    puts "  - 원본 길이: #{cl.analysis_result.length}"
    puts "  - 추출된 텍스트 길이: #{actual_text.length}"
    
    # 섹션 확인
    sections = actual_text.scan(/^##\s+\d+\./)
    puts "  - 발견된 섹션: #{sections.length}개"
    
    # 첫 500자 출력
    puts "\n추출된 텍스트 (첫 500자):"
    puts actual_text[0..500]
    
    # DB 업데이트
    cl.update!(analysis_result: actual_text)
    puts "\n✅ analysis_result 업데이트 완료"
    
    # 파싱 시도
    service = AdvancedCoverLetterService.new
    parsed = service.parse_analysis_to_json(actual_text)
    
    if parsed
      cl.update!(advanced_analysis_json: parsed)
      puts "\n✅ JSON 파싱 성공!"
      puts "파싱된 섹션:"
      parsed['sections'].each do |section|
        puts "  - 섹션 #{section['number']}: #{section['title']} (items: #{section['items'].length})"
      end
    else
      puts "\n❌ JSON 파싱 실패"
    end
  else
    puts "정규식 매칭 실패"
    
    # 수동으로 처리
    text = cl.analysis_result
    text = text.sub(/^\{text:\s*"/, '')
    text = text.sub(/"\}$/, '')
    text = text.gsub('\\n', "\n")
    text = text.gsub('\\"', '"')
    text = text.gsub('\\\\', '\\')
    
    puts "\n수동 추출 시도"
    puts "추출된 텍스트 길이: #{text.length}"
    
    cl.update!(analysis_result: text)
    
    # 파싱
    service = AdvancedCoverLetterService.new
    parsed = service.parse_analysis_to_json(text)
    
    if parsed
      cl.update!(advanced_analysis_json: parsed)
      puts "✅ 파싱 성공!"
    end
  end
else
  puts "✅ 정상적인 형식"
end