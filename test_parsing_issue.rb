#!/usr/bin/env ruby
require_relative 'config/environment'

# 스크린샷에서 보이는 강점 섹션 텍스트 (파싱 테스트용)
test_text = <<~TEXT
## 2. 잘 쓴 부분 (Top 5 강점)

### 강점 1: 구체적 비계 및 포토폴 표현

[1문단 - 문제를 지적한 장려 인력 진출]
카카오엔터 자기소개서를 읽다가 여러 경계에서 구체적인 수치와 시켜가 등장해주면서, 일부 적당 경험에 역량이나 크겨히 다소 오슈하저 편입되는 점이 이작읍니다. 매출 증어, "30번의 대외활동과 5년간의 아르바이트를 쟐했다고 명시할 받았정하는데, 직간다 무선"그가 집업를 매년 향고에 복간 저자를 을방하지 화고 입오는 시 스배 호기를 지원하더가도 같은 문장에서는 구매력을 몰련정으나 떠이 발치리온 시 고인 막갈파는서 힘없으 조 중웅맥 접법만곡으를 기라따 연절륜도으력 실을하단라 그리했음이더나, 말닌 슨 중마는 현혼을 이어 활동인도, 구체적인은 이와 할동이느지, 어떤 발지에론 시 주인들부터는 아닌 행동은 시 스배등 요기들이나라고 싶겨 헸목다는 것이 전달력을 놀업자는 합니다. 또한, "고객의 입성에 스미드는 스토리를 고객의 습운 나증를 찾아겠" 시어 인깨를 가해가 같은 은여적식은 이야어드와에 대무 공감하는 남구 선실입니다.

[2문단 - 추가 구체적인 조유잘 필요]
TEXT

puts "=== Testing Parsing Logic ==="
puts "Input text length: #{test_text.length}"

# 파싱 테스트
sections = []
current_section = nil

test_text.lines.each do |line|
  line = line.strip
  
  # 섹션 제목 매칭
  if line =~ /^##?\s*(\d+)\.\s*(.+)$/
    # 이전 섹션 저장
    sections << current_section if current_section
    
    current_section = {
      number: $1,
      title: $2.strip,
      content: [],
      items: []
    }
  # 항목 제목 매칭 (강점 1:, 개선점 1:, 보석 1: 등)
  elsif line =~ /^###?\s*(강점|개선점|보석)\s*(\d+)[:：]\s*(.+)$/
    if current_section
      current_section[:items] << {
        type: $1,
        number: $2,
        title: $3.strip,
        content: []
      }
    end
  # 대괄호로 시작하는 소제목
  elsif line =~ /^\[(.+)\]$/
    if current_section && current_section[:items].any?
      # 마지막 항목에 추가
      current_section[:items].last[:content] << "[#{$1}]"
    end
  # 일반 내용
  elsif !line.empty?
    if current_section
      if current_section[:items].any?
        # 항목이 있으면 마지막 항목에 추가
        current_section[:items].last[:content] << line
      else
        # 항목이 없으면 섹션 내용에 추가
        current_section[:content] << line
      end
    end
  end
end

# 마지막 섹션 저장
sections << current_section if current_section

# 결과 출력
sections.each do |section|
  puts "\n=== Section #{section[:number]}: #{section[:title]} ==="
  
  if section[:items].any?
    section[:items].each do |item|
      puts "\n  #{item[:type]} #{item[:number]}: #{item[:title]}"
      puts "  Content lines: #{item[:content].length}"
      puts "  First content: #{item[:content].first[0..100] if item[:content].any?}"
    end
  else
    puts "  Content lines: #{section[:content].length}"
  end
end