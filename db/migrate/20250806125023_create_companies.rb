class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :ticker
      t.text :description
      t.string :industry
      t.string :website

      t.timestamps
    end
  end
end
