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
  
  private
  
  def create_default_profile
    create_user_profile unless user_profile
  end
end
