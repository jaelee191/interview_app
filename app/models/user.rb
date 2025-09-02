class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_one :user_profile, dependent: :destroy
  has_many :cover_letters, dependent: :destroy
  has_many :job_analyses, dependent: :destroy
  has_many :company_analyses, dependent: :destroy

  # Create user profile after user creation
  after_create :create_default_profile
  after_create :grant_initial_free_credits
  after_create :ensure_referral_code

  private

  def create_default_profile
    create_user_profile unless user_profile
  end

  def grant_initial_free_credits
    # 최초 가입 시 무료 3건 제공 (이미 값이 있으면 건너뜀)
    if self.analysis_credits.to_i.zero? && self.free_analyses_used.to_i.zero?
      update_columns(analysis_credits: 3)
    end
  end

  def ensure_referral_code
    return if referral_code.present?
    loop do
      code = SecureRandom.urlsafe_base64(6).tr("-_", "ab")
      unless User.exists?(referral_code: code)
        update_columns(referral_code: code)
        break
      end
    end
  end
end
