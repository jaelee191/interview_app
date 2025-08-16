class CreateCompanyAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :company_analyses do |t|
      t.string :company_name
      t.string :industry
      t.string :company_size
      t.text :recent_issues
      t.text :business_context
      t.text :hiring_patterns
      t.text :competitor_info
      t.text :industry_trends
      t.datetime :analysis_date
      t.datetime :cached_until
      t.jsonb :metadata

      t.timestamps
    end
  end
end
