class AddAnalysisCreditsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :analysis_credits, :integer, default: 0, null: false
    add_column :users, :free_analyses_used, :integer, default: 0, null: false
  end
end
