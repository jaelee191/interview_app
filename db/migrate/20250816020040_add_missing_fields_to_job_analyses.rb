class AddMissingFieldsToJobAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_column :job_analyses, :user_id, :integer unless column_exists?(:job_analyses, :user_id)
    add_column :job_analyses, :saved, :boolean, default: false unless column_exists?(:job_analyses, :saved)
    add_column :job_analyses, :session_id, :string unless column_exists?(:job_analyses, :session_id)
    
    add_index :job_analyses, :user_id unless index_exists?(:job_analyses, :user_id)
    add_index :job_analyses, :session_id unless index_exists?(:job_analyses, :session_id)
  end
end
