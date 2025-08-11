class Article < ApplicationRecord
  # 유효성 검사
  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  validates :source, presence: true
  
  # 스코프
  scope :recent, -> { order(published_at: :desc) }
  scope :by_source, ->(source) { where(source: source) }
  scope :by_category, ->(category) { where(category: category) }
  scope :today, -> { where('published_at >= ?', Date.current.beginning_of_day) }
  
  # 검색 기능
  def self.search(query)
    where('title LIKE ? OR content LIKE ? OR summary LIKE ?', 
          "%#{query}%", "%#{query}%", "%#{query}%")
  end
end
