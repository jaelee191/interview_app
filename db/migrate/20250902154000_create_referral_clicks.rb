class CreateReferralClicks < ActiveRecord::Migration[7.1]
  def change
    create_table :referral_clicks do |t|
      t.string  :code, null: false
      t.integer :referrer_id
      t.string  :ip
      t.string  :user_agent
      t.string  :landing_path
      t.timestamps
    end
    add_index :referral_clicks, :code
    add_index :referral_clicks, :referrer_id
    add_index :referral_clicks, :created_at
  end
end
