class AddSavedToCoverLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :cover_letters, :saved, :boolean, default: false
    add_index :cover_letters, [:user_id, :saved]
  end
end
