class AddFieldsToJobAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_column :job_analyses, :summary, :text
  end
end
