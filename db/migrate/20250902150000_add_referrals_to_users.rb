class AddReferralsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :referral_code, :string
    add_index  :users, :referral_code, unique: true
    add_column :users, :referrer_id, :integer
    add_index  :users, :referrer_id
    add_column :users, :referral_bonus_claimed, :boolean, default: false, null: false
  end
end
