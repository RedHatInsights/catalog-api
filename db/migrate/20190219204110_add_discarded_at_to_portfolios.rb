class AddDiscardedAtToPortfolios < ActiveRecord::Migration[5.2]
  def change
    add_column :portfolios, :discarded_at, :datetime
    add_index :portfolios, :discarded_at
  end
end
