#!/usr/bin/env ruby
require_relative 'config/environment'

# 수정된 프롬프트 형식대로 작성된 테스트 텍스트
test_analysis = <<~TEXT
## 1. 첫인상 & 전체적인 느낌

지애님, 안녕하세요. 카카오엔터 마케팅 직무에 지원하신 자소서를 읽어보니 열정이 느껴집니다.

## 2. 잘 쓴 부분 (Top 5 강점)

### 강점 1: **구체적 수치 제시**

지원자님의 자소서에서 "30번의 대외활동과 5년간의 아르바이트"라는 부분이 매우 인상적이었습니다. 이런 구체적인 수치는 신뢰감을 줍니다.

HR 현장에서 이런 역량이 왜 중요한지 설명드리겠습니다. 숫자로 표현된 경험은 평가하기 쉽습니다.

더 인상적인 점은 단순히 숫자만 나열한 것이 아니라는 점입니다. 각 경험의 의미를 잘 설명했습니다.

### 강점 2: **고객 중심 사고**

고객 관점에서 생각하는 능력이 돋보입니다.

실제 사례를 통해 이를 증명했습니다.

이런 사고방식은 마케팅에서 핵심입니다.

## 3. 개선이 필요한 부분 (Top 5 개선점)

### 개선점 1: **문장 구조 개선 필요**

지원자님의 자소서를 읽다가 일부 문장이 너무 길다는 점을 발견했습니다. 가독성이 떨어집니다.

이게 왜 중요한지 실제 사례로 설명드릴게요. HR 담당자들은 수백 개의 자소서를 빠르게 읽어야 합니다.

이 부분을 이렇게 개선해보시면 좋겠습니다. 한 문장에 하나의 메시지만 담으세요.

### 개선점 2: **성과 구체화 필요**

활동은 많이 했지만 구체적 성과가 부족합니다.

정량적 지표를 추가하면 설득력이 높아집니다.

예를 들어 "매출 00% 증가" 같은 표현을 사용하세요.

## 4. 숨겨진 보석 찾기 (3개)

### 보석 1: **데이터 분석 역량**

지원자님의 자소서를 다시 읽다가 숨겨진 데이터 분석 능력을 발견했습니다. 이 부분은 큰 잠재력이 있습니다.

이 부분이 왜 중요한지 업계 트렌드와 연결해서 설명드리겠습니다. 마케팅에서 데이터는 핵심입니다.

이 역량을 이렇게 활용하면 더욱 강력한 자소서가 될 것입니다. 구체적 툴 경험을 추가하세요.

### 보석 2: **크로스 채널 경험**

온오프라인을 넘나드는 경험이 숨어있습니다.

이는 옴니채널 시대에 큰 자산입니다.

더 부각시켜보세요.

## 5. 마지막 격려와 응원

지애님, 충분한 잠재력을 가지고 계십니다. 화이팅!
TEXT

puts "=" * 80
puts "파싱 호환성 테스트"
puts "=" * 80

service = AdvancedCoverLetterService.new
parsed = service.parse_analysis_to_json(test_analysis)

if parsed
  puts "\n✅ 파싱 성공!"
  puts "\n섹션 개수: #{parsed['sections'].length}"
  
  parsed['sections'].each do |section|
    puts "\n📌 섹션 #{section['number']}: #{section['title']}"
    puts "   - content 길이: #{section['content'].length}"
    puts "   - items 개수: #{section['items'].length}"
    
    if section['items'].any?
      section['items'].each do |item|
        puts "     • #{item['type']} #{item['number']}: #{item['title']}"
        
        # 파싱이 제대로 되었는지 확인
        if item['content'].empty?
          puts "       ⚠️ 내용이 비어있음!"
        else
          puts "       ✅ 내용 있음 (#{item['content'].length}자)"
        end
      end
    end
  end
  
  # 파싱 문제 체크
  puts "\n🔍 파싱 문제 체크:"
  
  # 강점 섹션 체크
  strengths_section = parsed['sections'].find { |s| s['number'] == '2' }
  if strengths_section
    if strengths_section['items'].length == 2
      puts "✅ 강점 항목 2개 정상 파싱"
    else
      puts "⚠️ 강점 항목 개수: #{strengths_section['items'].length} (예상: 2)"
    end
  end
  
  # 개선점 섹션 체크
  improvements_section = parsed['sections'].find { |s| s['number'] == '3' }
  if improvements_section
    if improvements_section['items'].length == 2
      puts "✅ 개선점 항목 2개 정상 파싱"
    else
      puts "⚠️ 개선점 항목 개수: #{improvements_section['items'].length} (예상: 2)"
    end
  end
  
  # 보석 섹션 체크
  gems_section = parsed['sections'].find { |s| s['number'] == '4' }
  if gems_section
    if gems_section['items'].length == 2
      puts "✅ 보석 항목 2개 정상 파싱"
    else
      puts "⚠️ 보석 항목 개수: #{gems_section['items'].length} (예상: 2)"
    end
  end
  
else
  puts "❌ 파싱 실패!"
end