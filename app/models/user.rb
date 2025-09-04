class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:naver]

  # Associations
  has_one :user_profile, dependent: :destroy
  has_many :cover_letters, dependent: :destroy
  has_many :job_analyses, dependent: :destroy
  has_many :company_analyses, dependent: :destroy

  # Create user profile after user creation
  after_create :create_default_profile
  after_create :grant_initial_free_credits
  after_create :ensure_referral_code

  # Omniauth methods
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      # user.image = auth.info.image # 프로필 이미지 저장 시
    end
  end

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
