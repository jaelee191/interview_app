class ReferralReview < ApplicationRecord
  belongs_to :user
  validates :content, presence: true, length: { maximum: 500 }
end
