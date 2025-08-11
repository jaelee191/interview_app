class CompanyNews < ApplicationRecord
  belongs_to :company
  
  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  
  scope :recent, -> { order(published_at: :desc) }
  scope :positive, -> { where(sentiment: 'positive') }
  scope :negative, -> { where(sentiment: 'negative') }
  scope :neutral, -> { where(sentiment: 'neutral') }
end
