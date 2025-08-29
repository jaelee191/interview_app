class AddImprovedLetterToCoverLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :cover_letters, :improved_letter, :text
    add_column :cover_letters, :improved_letter_saved_at, :datetime
  end
end
