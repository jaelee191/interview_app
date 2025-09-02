class CreatePaymentLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :order_id, null: false
      t.string :payment_key
      t.integer :amount, null: false
      t.string :status, null: false, default: 'DONE'
      t.jsonb :raw_response
      t.timestamps
    end
    add_index :payment_logs, :order_id, unique: true
  end
end
