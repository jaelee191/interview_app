class ChatSession < ApplicationRecord
  serialize :content, coder: JSON
  serialize :messages, coder: JSON
  serialize :question_count, coder: JSON
  
  before_create :generate_session_id
  
  private
  
  def generate_session_id
    self.session_id ||= SecureRandom.hex(16)
  end
end
