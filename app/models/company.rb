class Company < ApplicationRecord
  has_many :company_news, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  
  # 검색 기능
  scope :search, ->(query) { where('name LIKE ? OR ticker LIKE ?', "%#{query}%", "%#{query}%") }
end
