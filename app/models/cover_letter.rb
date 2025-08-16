class CoverLetter < ApplicationRecord
  belongs_to :user, optional: true
  
  # Validations
  validates :content, presence: true
end
