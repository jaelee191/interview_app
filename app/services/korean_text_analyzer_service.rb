class KoreanTextAnalyzerService
  PYTHON_SCRIPT_PATH = Rails.root.join('lib', 'python', 'korean_text_analyzer.py').to_s

  class << self
    # 텍스트에서 섹션 추출
    def extract_sections(text)
      return {} unless text.present?
      
      result = execute_python_command('extract_sections', text)
      return {} unless result['success']
      
      # 심볼 키로 변환
      result['data'].transform_keys(&:to_sym)
    rescue => e
      Rails.logger.error "Korean text extraction failed: #{e.message}"
      fallback_extract_sections(text)
    end

    # 번호가 매겨진 항목들 파싱
    def parse_numbered_items(text)
      return [] unless text.present?
      
      result = execute_python_command('parse_items', text)
      return [] unless result['success']
      
      # 각 항목의 키를 심볼로 변환
      result['data'].map { |item| item.transform_keys(&:to_sym) }
    rescue => e
      Rails.logger.error "Korean text parsing failed: #{e.message}"
      fallback_parse_items(text)
    end

    # 한글 띄어쓰기 정규화
    def normalize_spacing(text)
      return text unless text.present?
      
      result = execute_python_command('normalize', text)
      return text unless result['success']
      
      result['data']['text']
    rescue => e
      Rails.logger.error "Korean text normalization failed: #{e.message}"
      text
    end

    # 자소서 구조 자동 감지
    def detect_structure(text)
      return {} unless text.present?
      
      result = execute_python_command('detect_structure', text)
      return {} unless result['success']
      
      result['data'].transform_keys(&:to_sym)
    rescue => e
      Rails.logger.error "Structure detection failed: #{e.message}"
      { has_numbered_sections: false, section_count: 0, section_titles: [], format_type: 'unknown' }
    end

    # 지능형 섹션 분리
    def smart_split_sections(text)
      return [] unless text.present?
      
      result = execute_python_command('smart_split', text)
      return [] unless result['success']
      
      result['data'].map { |item| item.transform_keys(&:to_sym) }
    rescue => e
      Rails.logger.error "Smart split failed: #{e.message}"
      []
    end

    private

    def execute_python_command(command, input_text)
      # Python 실행 가능 여부 확인
      unless File.exist?(PYTHON_SCRIPT_PATH)
        Rails.logger.error "Python script not found at #{PYTHON_SCRIPT_PATH}"
        return { 'success' => false, 'error' => 'Python script not found' }
      end

      # Python 명령 실행
      output, error, status = Open3.capture3(
        'python3', PYTHON_SCRIPT_PATH, command,
        stdin_data: input_text
      )

      if status.success?
        begin
          data = JSON.parse(output)
          { 'success' => true, 'data' => data }
        rescue JSON::ParserError => e
          Rails.logger.error "Failed to parse Python output: #{e.message}"
          Rails.logger.error "Output was: #{output}"
          { 'success' => false, 'error' => "Invalid JSON response: #{e.message}" }
        end
      else
        Rails.logger.error "Python execution failed: #{error}"
        { 'success' => false, 'error' => error }
      end
    end

    # Ruby 기반 폴백 메서드들 (Python 실행 실패 시)
    def fallback_extract_sections(text)
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
      
      # 기존 Ruby 패턴 사용
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

    def fallback_parse_items(text)
      return [] unless text
      
      items = []
      
      # 개선된 정규식 패턴 (띄어쓰기 있는 한글도 처리)
      if text.match(/###\s+[가-힣]+(?:\s+[가-힣]+)*\s+\d+:/)
        sections = text.scan(/###\s+([가-힣]+(?:\s+[가-힣]+)*\s+\d+:\s*[^\n]+)\n+([^#]+)/)
        
        sections.each do |title, content|
          if match = title.match(/([가-힣]+(?:\s+[가-힣]+)*)\s+(\d+):\s*(.+)/)
            items << {
              number: match[2],
              title: title.strip,
              content: content.strip
            }
          end
        end
      elsif text.match(/\*\*[가-힣]+\s+\d+:/)
        sections = text.split(/(?=\*\*[가-힣]+\s+\d+:)/)
        
        sections.each do |section|
          next if section.strip.empty?
          
          if match = section.match(/\*\*([가-힣]+)\s+(\d+):\s*([^*]+)\*\*(.*)$/m)
            items << {
              number: match[2],
              title: "#{match[1]} #{match[2]}: #{match[3].strip}",
              content: match[4].strip.gsub(/\n+/, ' ')
            }
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

    def extract_section_flexible(text, pattern)
      match = text.match(pattern)
      return nil unless match
      
      content_start = match.end(0)
      
      if newline_idx = text[content_start..-1].index("\n")
        content_start = content_start + newline_idx + 1
      end
      
      next_patterns = [
        /\n\s*##\s*\d+\./,
        /\n═+/,
        /\Z/
      ]
      
      end_index = nil
      next_patterns.each do |next_pattern|
        if next_match = text[content_start..-1].match(next_pattern)
          end_index = content_start + next_match.begin(0)
          break
        end
      end
      
      if end_index
        text[content_start...end_index].strip
      else
        text[content_start..-1].strip
      end
    end
  end
end