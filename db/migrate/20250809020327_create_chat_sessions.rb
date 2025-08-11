class CreateChatSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_sessions do |t|
      t.string :session_id
      t.string :company_name
      t.string :position
      t.string :current_step
      t.text :content
      t.text :messages
      t.text :final_content
      t.text :question_count

      t.timestamps
    end
    add_index :chat_sessions, :session_id
  end
end
