class AddUserIdToCoverLetters < ActiveRecord::Migration[8.0]
  def change
    add_reference :cover_letters, :user, null: true, foreign_key: true
  end
end
