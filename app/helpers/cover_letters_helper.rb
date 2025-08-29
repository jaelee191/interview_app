module CoverLettersHelper
  def parse_analysis_sections(text)
    sections = {
      first_impression: nil,
      strengths: nil,
      improvements: nil,
      hidden_gems: nil,
      encouragement: nil
    }
    
    return sections unless text
    
    # 특수문자 제거 및 정리
    cleaned_text = text.gsub(/[═─]+/, '').strip
    
    # 다양한 섹션 마커 패턴 지원 (더 유연하게)
    patterns = {
      first_impression: [/##\s*1\.\s*첫인상/, /첫인상\s*&\s*전체/],
      strengths: [/##\s*2\.\s*잘\s*쓴\s*부분/],
      improvements: [/##\s*3\.\s*아쉬운\s*부분/, /##\s*3\.\s*개선.*부분/],
      hidden_gems: [/##\s*4\.\s*놓치고\s*있는\s*숨은\s*보석/],
      encouragement: [/##\s*5\.\s*격려와\s*응원/]
    }
    
    patterns.each do |key, pattern_list|
      pattern_list.each do |pattern|
        if cleaned_text.match(pattern)
          sections[key] = extract_section_flexible(cleaned_text, pattern)
          break if sections[key] && !sections[key].empty?
        end
      end
    end
    
    # 섹션이 하나도 찾아지지 않으면 전체 텍스트를 첫인상으로
    if sections.values.all?(&:nil?)
      sections[:first_impression] = cleaned_text
    end
    
    sections
  end

  def extract_section(text, start_marker, end_marker)
    start_index = text.index(start_marker)
    return nil unless start_index
    
    start_index += start_marker.length
    
    if end_marker
      end_index = text.index(end_marker, start_index)
      end_index ? text[start_index...end_index].strip : text[start_index..-1].strip
    else
      text[start_index..-1].strip
    end
  end
  
  def extract_section_flexible(text, pattern)
    match = text.match(pattern)
    return nil unless match
    
    # 헤더 이후부터 시작
    content_start = match.end(0)
    
    # 헤더 줄의 나머지 부분(예: "(Top 5 강점)") 스킵
    # 첫 줄바꿈 이후부터 시작
    if newline_idx = text[content_start..-1].index("\n")
      content_start = content_start + newline_idx + 1
    end
    
    # 다음 섹션 패턴들
    next_patterns = [
      /\n\s*##\s*\d+\./,  # ## 5. 같은 패턴
      /\n═+/,  # 구분선
      /\Z/  # 문서 끝
    ]
    
    end_index = nil
    next_patterns.each do |next_pattern|
      if next_match = text[content_start..-1].match(next_pattern)
        end_index = content_start + next_match.begin(0)
        break
      end
    end
    
    # 추출된 내용 반환
    if end_index
      text[content_start...end_index].strip
    else
      text[content_start..-1].strip
    end
  end

  def parse_numbered_items(text)
    return [] unless text
    
    items = []
    
    # "**강점 1:", "**개선점 1:" 등의 패턴 처리
    if text.match(/\*\*[가-힣]+\s+\d+:/)
      # 각 항목별로 분리
      sections = text.split(/(?=\*\*[가-힣]+\s+\d+:)/)
      
      sections.each do |section|
        next if section.strip.empty?
        
        # **강점 1: 제목** 형식 파싱
        if match = section.match(/\*\*([가-힣]+)\s+(\d+):\s*([^*]+)\*\*(.*)$/m)
          items << {
            number: match[2],
            title: "#{match[1]} #{match[2]}: #{match[3].strip}",
            content: match[4].strip.gsub(/\n+/, ' ')
          }
        end
      end
    # "숨은 보석 1:" 패턴 처리
    elsif text.include?('숨은 보석')
      sections = text.split(/\*\*숨은 보석\s+(\d+):/)
      sections.shift if sections.first && !sections.first.match(/\d/)
      
      sections.each_slice(2) do |number, content|
        next unless number && content
        
        if match = content.match(/^\s*([^*\n]+)\*\*(.*)$/m)
          items << {
            number: number.strip,
            title: "숨은 보석 #{number.strip}: #{match[1].strip}",
            content: match[2].strip.gsub(/\n+/, ' ')
          }
        end
      end
    # ##으로 시작하는 항목 처리
    elsif text.include?('##')
      sections = text.split(/(?=##\s*\d+)/)
      sections.each do |section|
        next if section.strip.empty?
        
        if match = section.match(/##\s*(\d+)\.?\s*(.*)$/m)
          content = match[2].strip
          # 제목과 내용 분리
          lines = content.split("\n", 2)
          if lines.length >= 2
            items << {
              number: match[1],
              title: lines[0].strip,
              content: lines[1].strip.gsub(/\n/, ' ')
            }
          else
            items << {
              number: match[1],
              title: '',
              content: content
            }
          end
        end
      end
    else
      # 기존 번호 매기기 패턴 처리
      lines = text.split(/\n(?=\d+\.)/)
      
      lines.each do |line|
        if match = line.match(/^(\d+)\.\s*\*\*(.*?)\*\*(.*)$/m)
          items << {
            number: match[1],
            title: match[2].strip,
            content: match[3].strip.gsub(/^[\s\-:]+/, '').gsub(/\n/, ' ')
          }
        elsif match = line.match(/^(\d+)\.\s*(.*)$/m)
          parts = match[2].split(/[:：]/, 2)
          if parts.length == 2
            items << {
              number: match[1],
              title: parts[0].strip,
              content: parts[1].strip.gsub(/\n/, ' ')
            }
          else
            content = match[2].strip
            # 첫 문장을 제목으로 사용
            sentences = content.split(/[.。]/)
            if sentences.length > 1
              items << {
                number: match[1],
                title: sentences[0].strip,
                content: sentences[1..-1].join('. ').strip
              }
            else
              items << {
                number: match[1],
                title: '',
                content: content
              }
            end
          end
        end
      end
    end
    
    items
  end

  def format_analysis_text(text)
    TextFormatterService.new.format_section_text(text)
  end
  
  def format_full_analysis(text)
    TextFormatterService.new.format_full_analysis(text)
  end
  
  def format_inline_text(text, escape_html = true)
    TextFormatterService.new.format_section_text(text)
  end
  
  def markdown_to_html(text)
    return '' unless text.present?
    
    renderer = Redcarpet::Render::HTML.new(
      filter_html: false,
      no_images: false,
      no_links: false,
      safe_links_only: true,
      hard_wrap: true
    )
    
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      no_intra_emphasis: true,
      fenced_code_blocks: true,
      lax_spacing: true,
      strikethrough: true,
      superscript: true,
      tables: true
    )
    
    markdown.render(text).html_safe
  rescue => e
    # Fallback to simple format if markdown parsing fails
    simple_format(text)
  end
end
