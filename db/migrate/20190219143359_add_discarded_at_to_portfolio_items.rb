class AddDiscardedAtToPortfolioItems < ActiveRecord::Migration[5.2]
  def change
    add_column :portfolio_items, :discarded_at, :datetime
    add_index :portfolio_items, :discarded_at
  end
end
