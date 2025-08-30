class AddAnalysisStatusToCoverLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :cover_letters, :analysis_status, :string
    add_column :cover_letters, :analysis_started_at, :datetime
    add_column :cover_letters, :analysis_completed_at, :datetime
    add_column :cover_letters, :analysis_error, :text
  end
end
