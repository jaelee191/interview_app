class AddUserAndSavedToCompanyAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_reference :company_analyses, :user, null: true, foreign_key: true
    add_column :company_analyses, :saved, :boolean, default: false
    add_column :company_analyses, :session_id, :string
    
    add_index :company_analyses, :session_id
    add_index :company_analyses, :saved
  end
end
