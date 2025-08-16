class CompanyAnalysis < ApplicationRecord
  belongs_to :user, optional: true
  
  validates :company_name, presence: true
  
  # 캐시 유효성 검사
  def cache_valid?
    cached_until.present? && cached_until > Time.current
  end
  
  # 스코프
  scope :recent, -> { where('cached_until > ?', Time.current) }
  scope :by_company, ->(name) { where(company_name: name) }
  scope :saved, -> { where(saved: true) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_session, ->(session_id) { where(session_id: session_id) }
  
  # 분석 데이터 구조화
  def structured_data
    {
      company_info: {
        name: company_name,
        industry: industry,
        size: company_size
      },
      analysis: {
        recent_issues: parse_json_or_text(recent_issues),
        business_context: parse_json_or_text(business_context),
        hiring_patterns: parse_json_or_text(hiring_patterns),
        competitor_info: parse_json_or_text(competitor_info),
        industry_trends: parse_json_or_text(industry_trends)
      },
      metadata: metadata || {},
      analyzed_at: analysis_date,
      expires_at: cached_until
    }
  end
  
  private
  
  def parse_json_or_text(field)
    return nil if field.blank?
    
    begin
      JSON.parse(field)
    rescue JSON::ParserError
      field
    end
  end
end
