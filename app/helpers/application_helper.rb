module ApplicationHelper
  def score_color(score)
    return 'text-gray-500' unless score
    
    case score
    when 80..100
      'text-green-600'
    when 60..79
      'text-blue-600'
    when 40..59
      'text-yellow-600'
    else
      'text-red-600'
    end
  end
  
  def markdown_to_html(text)
    return "" if text.blank?
    
    # Redcarpet 렌더러 설정
    renderer = Redcarpet::Render::HTML.new(
      filter_html: false,
      hard_wrap: true,
      tables: true,
      fenced_code_blocks: true,
      autolink: true,
      strikethrough: true,
      escape_html: false
    )
    
    # 마크다운 파서 설정
    markdown = Redcarpet::Markdown.new(renderer,
      no_intra_emphasis: true,
      tables: true,
      fenced_code_blocks: true,
      autolink: true,
      strikethrough: true,
      lax_spacing: true,
      space_after_headers: true,
      superscript: true
    )
    
    # 마크다운을 HTML로 변환
    html = markdown.render(text.to_s)
    
    # Tailwind 클래스 추가 (정규표현식으로 태그에 클래스 추가)
    html = html.gsub(/<h1>/, '<h1 class="text-3xl font-bold mb-4 mt-6 text-gray-900">')
    html = html.gsub(/<h2>/, '<h2 class="text-2xl font-bold mb-3 mt-5 text-blue-900 border-b-2 border-gray-200 pb-2">')
    html = html.gsub(/<h3>/, '<h3 class="text-xl font-semibold mb-2 mt-4 text-gray-800">')
    html = html.gsub(/<h4>/, '<h4 class="text-lg font-semibold mb-2 mt-3 text-gray-700">')
    html = html.gsub(/<p>/, '<p class="mb-4 leading-relaxed text-gray-700">')
    html = html.gsub(/<ul>/, '<ul class="list-disc list-inside mb-4 space-y-2">')
    html = html.gsub(/<ol>/, '<ol class="list-decimal list-inside mb-4 space-y-2">')
    html = html.gsub(/<li>/, '<li class="ml-4">')
    html = html.gsub(/<strong>/, '<strong class="font-bold text-gray-900">')
    html = html.gsub(/<em>/, '<em class="italic">')
    html = html.gsub(/<blockquote>/, '<blockquote class="border-l-4 border-blue-500 pl-4 py-2 mb-4 bg-gray-50 italic">')
    html = html.gsub(/<code>/, '<code class="bg-gray-100 px-2 py-1 rounded text-sm font-mono">')
    html = html.gsub(/<pre>/, '<pre class="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto mb-4">')
    
    # 테이블 스타일링
    html = html.gsub(/<table>/, '<table class="w-full border-collapse mb-4">')
    html = html.gsub(/<thead>/, '<thead class="bg-gray-100">')
    html = html.gsub(/<th>/, '<th class="border border-gray-300 px-4 py-2 text-left font-semibold">')
    html = html.gsub(/<td>/, '<td class="border border-gray-300 px-4 py-2">')
    html = html.gsub(/<tr>/, '<tr class="hover:bg-gray-50">')
    
    # 화살표와 특수 문자 처리
    html = html.gsub('→', '<span class="text-blue-600 font-bold">→</span>')
    html = html.gsub('👉', '<span class="text-xl">👉</span>')
    html = html.gsub('[취업 TIP]', '<span class="bg-yellow-100 text-yellow-800 px-2 py-1 rounded font-bold">취업 TIP</span>')
    
    html.html_safe
  end
  
  def parse_analysis_sections(analysis_text)
    return [] if analysis_text.blank?
    
    sections = []
    current_section = nil
    current_content = []
    
    lines = analysis_text.split("\n")
    
    lines.each do |line|
      # Check if this line starts a new section (## 1. Title format)
      if line.match(/^##\s+(\d+)\.\s+(.+)/)
        # Save previous section if exists
        if current_section
          sections << {
            number: current_section[:number],
            title: current_section[:title],
            content: current_content.join("\n").strip
          }
        end
        
        # Start new section
        match = line.match(/^##\s+(\d+)\.\s+(.+)/)
        current_section = {
          number: match[1].to_i,
          title: match[2].strip
        }
        current_content = []
      elsif current_section
        # Add content to current section
        current_content << line
      end
    end
    
    # Save last section
    if current_section
      sections << {
        number: current_section[:number],
        title: current_section[:title],
        content: current_content.join("\n").strip
      }
    end
    
    # If no sections found, treat entire content as one section
    if sections.empty? && analysis_text.present?
      sections << {
        number: 1,
        title: "분석 내용",
        content: analysis_text
      }
    end
    
    sections
  end
  
  def parse_numbered_items(section_content)
    return [] if section_content.blank?
    
    items = []
    current_item = nil
    current_content = []
    
    section_content.split("\n").each do |line|
      # Look for numbered items like "### 1. Title" or "**1) Title**"
      if line.match(/^###\s+(\d+)\.?\s*(.+)/) || line.match(/^\*\*(\d+)\)\s*(.+)\*\*/)
        # Save previous item if exists
        if current_item
          items << {
            title: current_item[:title],
            content: current_content.join("\n").strip
          }
        end
        
        # Start new item
        title = line.match(/^###\s+\d+\.?\s*(.+)/) ? line.match(/^###\s+\d+\.?\s*(.+)/)[1] : 
                line.match(/^\*\*\d+\)\s*(.+)\*\*/)[1]
        current_item = { title: title }
        current_content = []
      elsif current_item
        # Add content to current item
        current_content << line unless line.strip.empty? && current_content.empty?
      end
    end
    
    # Add the last item
    if current_item && current_content.any?
      items << {
        title: current_item[:title],
        content: current_content.join("\n").strip
      }
    end
    
    # If no numbered items found, treat entire content as single item
    if items.empty? && section_content.present?
      items << {
        title: '',
        content: section_content
      }
    end
    
    items
  end
end