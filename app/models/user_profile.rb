class UserProfile < ApplicationRecord
  belongs_to :user
  
  # Associations
  has_many :ontology_analyses, dependent: :destroy
  
  # Validations
  validates :user_id, uniqueness: true
  
  # Default values
  after_initialize :set_defaults
  
  private
  
  def set_defaults
    self.career_history ||= []
    self.projects ||= []
    self.technical_skills ||= []
  end
end
