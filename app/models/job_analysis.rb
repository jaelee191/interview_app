class JobAnalysis < ApplicationRecord
  validates :url, presence: true
  
  # Serialize arrays as JSON
  serialize :keywords, coder: JSON
  serialize :required_skills, coder: JSON
  serialize :company_values, coder: JSON
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_company, ->(name) { where(company_name: name) }
  
  # Extract key information from analysis
  def extract_key_info
    return unless analysis_result.present?
    
    # Extract company name
    if match = analysis_result.match(/\*\*기업명\*\*:\s*(.+)/)
      self.company_name = match[1].strip
    end
    
    # Extract position
    if match = analysis_result.match(/\*\*모집 직무\*\*:\s*(.+)/)
      self.position = match[1].strip
    end
    
    # Extract keywords
    keywords_section = analysis_result.match(/### 🎯 핵심 키워드.*?\n(.*?)###/m)
    if keywords_section
      self.keywords = keywords_section[1].scan(/\d+\.\s*\*\*(.+?)\*\*/).flatten
    end
    
    # Extract required skills
    skills_section = analysis_result.match(/### 💪 필수 역량.*?\n(.*?)###/m)
    if skills_section
      self.required_skills = skills_section[1].scan(/- (.+)/).flatten
    end
    
    # Extract company values
    values_section = analysis_result.match(/\*\*핵심 가치\*\*.*?\n(.*?)(?:\*\*|###)/m)
    if values_section
      self.company_values = values_section[1].scan(/- (.+)/).flatten
    end
  end
  
  # Check if analysis is recent (within 7 days)
  def recent?
    created_at > 7.days.ago
  end
  
  # Get summary for display
  def summary_hash
    {
      company: company_name || "분석 중",
      position: position || "분석 중",
      keywords_count: keywords&.size || 0,
      skills_count: required_skills&.size || 0,
      values_count: company_values&.size || 0
    }
  end
  
  # Get summary text for display
  def summary
    return nil unless analysis_result.present?
    
    # Try to extract summary from enhanced analysis first
    if analysis_result.include?('"executive_summary"')
      begin
        data = JSON.parse(analysis_result)
        return data["executive_summary"] if data["executive_summary"]
      rescue JSON::ParserError
        # Continue to try other methods
      end
    end
    
    # Try to extract from markdown format
    if match = analysis_result.match(/## 📊 분석 요약.*?\n(.*?)(?:##|###|\z)/m)
      return match[1].strip.gsub(/\*\*/, '').gsub(/\n+/, ' ')
    end
    
    # Try to extract from company context
    if match = analysis_result.match(/회사 소개.*?:\s*(.*?)(?:\n|$)/i)
      intro = match[1].strip[0..200]
      return "#{company_name} - #{position}: #{intro}..."
    end
    
    # Fallback: Create summary from available data
    parts = []
    parts << "#{company_name}" if company_name
    parts << "#{position} 채용" if position
    parts << "핵심 키워드 #{keywords&.size || 0}개" if keywords&.any?
    parts << "필수 역량 #{required_skills&.size || 0}개" if required_skills&.any?
    
    parts.any? ? parts.join(' | ') : nil
  end
end
