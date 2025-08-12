class CreateJobPostingCaches < ActiveRecord::Migration[8.0]
  def change
    create_table :job_posting_caches do |t|
      t.string :url, null: false
      t.text :content
      t.datetime :cached_at
      
      t.timestamps
    end
    
    add_index :job_posting_caches, :url, unique: true
    add_index :job_posting_caches, :cached_at
  end
end
