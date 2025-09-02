class AddResumeFieldsToCoverLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :cover_letters, :resume_content, :text
    add_column :cover_letters, :resume_json, :jsonb
    add_column :cover_letters, :resume_analysis, :text
  end
end
