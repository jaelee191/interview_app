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
    
    # 다양한 섹션 마커 패턴 지원
    # ## 첫인상, **첫인상**, 1. 첫인상 등
    patterns = {
      first_impression: [/##\s*첫인상/, /\*\*첫인상/, /^\s*첫인상/],
      strengths: [/##\s*잘\s*쓴\s*부분/, /\*\*잘\s*쓴\s*부분/, /^\s*잘\s*쓴\s*부분/],
      improvements: [/##\s*개선이?\s*필요한?\s*부분/, /\*\*개선이?\s*필요한?\s*부분/, /^\s*개선이?\s*필요한?\s*부분/],
      hidden_gems: [/##\s*숨은\s*보석/, /\*\*숨은\s*보석/, /^\s*숨은\s*보석/],
      encouragement: [/##\s*격려/, /\*\*격려/, /^\s*격려/]
    }
    
    patterns.each do |key, pattern_list|
      pattern_list.each do |pattern|
        if text.match(pattern)
          sections[key] = extract_section_flexible(text, pattern)
          break
        end
      end
    end
    
    # 섹션이 하나도 찾아지지 않으면 전체 텍스트를 첫인상으로
    if sections.values.all?(&:nil?)
      sections[:first_impression] = text
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
    
    start_index = match.end(0)
    
    # 다음 섹션 패턴들
    next_patterns = [
      /\n\s*##\s*[가-힣]+/,
      /\n\s*\*\*[가-힣]+\*\*/,
      /\n\s*\d+\.\s*[가-힣]+/,
      /\n---/
    ]
    
    end_index = nil
    next_patterns.each do |next_pattern|
      if next_match = text[start_index..-1].match(next_pattern)
        end_index = start_index + next_match.begin(0)
        break
      end
    end
    
    end_index ? text[start_index...end_index].strip : text[start_index..-1].strip
  end

  def parse_numbered_items(text)
    return [] unless text
    
    items = []
    
    # ##으로 시작하는 항목 처리
    if text.include?('##')
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
end
