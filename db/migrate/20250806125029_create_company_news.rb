class CreateCompanyNews < ActiveRecord::Migration[8.0]
  def change
    create_table :company_news do |t|
      t.references :company, null: false, foreign_key: true
      t.string :title
      t.text :content
      t.string :url
      t.string :source
      t.datetime :published_at
      t.string :sentiment
      t.text :summary

      t.timestamps
    end
  end
end
