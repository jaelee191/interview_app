class CreateJobAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :job_analyses do |t|
      t.string :url
      t.string :company_name
      t.string :position
      t.text :analysis_result
      t.text :keywords
      t.text :required_skills
      t.text :company_values

      t.timestamps
    end
  end
end
