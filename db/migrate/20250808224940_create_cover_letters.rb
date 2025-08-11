class CreateCoverLetters < ActiveRecord::Migration[8.0]
  def change
    create_table :cover_letters do |t|
      t.string :title
      t.text :content
      t.text :analysis_result
      t.string :company_name
      t.string :position
      t.string :user_name

      t.timestamps
    end
  end
end
