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
  def summary
    {
      company: company_name || "분석 중",
      position: position || "분석 중",
      keywords_count: keywords&.size || 0,
      skills_count: required_skills&.size || 0,
      values_count: company_values&.size || 0
    }
  end
end
