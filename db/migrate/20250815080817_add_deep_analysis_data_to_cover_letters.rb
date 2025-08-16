class AddDeepAnalysisDataToCoverLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :cover_letters, :deep_analysis_data, :jsonb
  end
end
