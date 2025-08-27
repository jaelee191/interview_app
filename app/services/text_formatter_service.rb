class TextFormatterService
  def initialize
    # Define safe HTML patterns
    @safe_patterns = {
      # Bold text patterns
      bold: /\*\*([^\*]+)\*\*/,
      # Section headers
      section_headers: /^##\s+(.+)$/m,
      numbered_sections: /^##\s*(\d+)\.\s*(.+)$/m,
      # Numbered lists
      numbered_list: /^(\d+)\.\s+(.+)$/m,
      numbered_list_with_bold: /^(\d+)\.\s*\*\*([^\*]+)\*\*:?\s*(.+)$/m,
      # Separators
      thick_separator: /═{3,}/,
      thin_separator: /[-─]{3,}/
    }
  end

  def format_full_analysis(text)
    return '' unless text.present?
    
    # Start with clean text
    formatted = text.to_s.dup
    
    # First, escape HTML to prevent injection
    formatted = CGI.escapeHTML(formatted)
    
    # Apply formatting patterns safely
    formatted = apply_separator_formatting(formatted)
    formatted = apply_header_formatting(formatted)
    formatted = apply_list_formatting(formatted)
    formatted = apply_text_styling(formatted)
    formatted = wrap_in_paragraphs(formatted)
    
    formatted.html_safe
  end

  def format_section_text(text)
    return '' unless text.present?
    
    # Simple inline formatting for sections
    formatted = CGI.escapeHTML(text.to_s)
    formatted = apply_text_styling(formatted)
    formatted.html_safe
  end

  private

  def apply_separator_formatting(text)
    # Handle separators
    text.gsub!(@safe_patterns[:thick_separator], '<hr class="my-8 border-gray-200">')
    text.gsub!(@safe_patterns[:thin_separator], '<hr class="my-6 border-gray-100">')
    text
  end

  def apply_header_formatting(text)
    # Handle numbered section headers
    text.gsub!(@safe_patterns[:numbered_sections]) do
      number = $1
      heading = $2
      %Q{<h4 class="text-lg font-semibold text-gray-900 mt-6 mb-3 flex items-center">
        <span class="inline-flex items-center justify-center w-7 h-7 bg-emerald-100 text-emerald-700 rounded-full text-sm font-semibold mr-3">#{number}</span>
        #{heading}
      </h4>}
    end
    
    # Handle regular section headers
    text.gsub!(@safe_patterns[:section_headers]) do
      %Q{<h4 class="text-lg font-semibold text-gray-900 mt-6 mb-3">#{$1}</h4>}
    end
    
    text
  end

  def apply_list_formatting(text)
    # Handle numbered lists with bold titles
    text.gsub!(@safe_patterns[:numbered_list_with_bold]) do
      number = $1
      title = $2
      description = $3
      %Q{<div class="flex items-start mb-3">
        <span class="inline-flex items-center justify-center w-6 h-6 bg-emerald-50 text-emerald-700 rounded-full text-xs font-semibold mr-3 flex-shrink-0">#{number}</span>
        <div class="flex-1">
          <div class="font-medium text-gray-900 text-sm">#{title}</div>
          <div class="text-gray-600 text-sm mt-1 leading-relaxed">#{description}</div>
        </div>
      </div>}
    end
    
    # Handle simple numbered lists
    text.gsub!(@safe_patterns[:numbered_list]) do
      number = $1
      content = $2
      # Skip if already processed as a list with bold
      next $& if content.include?('</div>')
      
      %Q{<div class="flex items-start mb-2">
        <span class="inline-flex items-center justify-center w-6 h-6 bg-emerald-50 text-emerald-700 rounded-full text-xs font-semibold mr-3 flex-shrink-0">#{number}</span>
        <div class="flex-1 text-gray-700 text-sm leading-relaxed">#{content}</div>
      </div>}
    end
    
    text
  end

  def apply_text_styling(text)
    # Handle bold text first
    text.gsub!(@safe_patterns[:bold]) do
      %Q{<strong class="font-semibold text-gray-900">#{$1}</strong>}
    end
    
    # Handle quoted text carefully - only match quoted text that's not part of HTML attributes
    # Avoid matching quotes within class="..." or other attributes
    text.gsub!(/"([^"]+)"(?![^<]*>)/) do
      %Q{<span class="text-emerald-600">"#{$1}"</span>}
    end
    
    text.gsub!(/'([^']+)'(?![^<]*>)/) do
      %Q{<span class="text-emerald-600">'#{$1}'</span>}
    end
    
    text
  end

  def wrap_in_paragraphs(text)
    # Split by double newlines to create paragraphs
    paragraphs = text.split(/\n\n+/)
    
    formatted_paragraphs = paragraphs.map do |paragraph|
      paragraph = paragraph.strip
      next if paragraph.empty?
      
      # Skip if already contains HTML elements
      if paragraph.include?('<h4') || paragraph.include?('<div class="flex') || paragraph.include?('<hr')
        paragraph
      else
        # Wrap in paragraph tags with more spacing
        %Q{<p class="text-gray-700 leading-loose mb-6">#{paragraph.gsub(/\n/, ' ')}</p>}
      end
    end
    
    formatted_paragraphs.compact.join("\n")
  end
end