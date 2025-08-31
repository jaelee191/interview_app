class AddJsonFieldsToCoverLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :cover_letters, :advanced_analysis_json, :jsonb
  end
end
