class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.string :title
      t.text :content
      t.string :url
      t.string :source
      t.datetime :published_at
      t.string :author
      t.string :category
      t.text :summary
      t.string :image_url

      t.timestamps
    end
  end
end
