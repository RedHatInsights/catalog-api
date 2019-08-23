class AddDiscardedAtToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :discarded_at, :datetime
    add_index :orders, :discarded_at
  end
end
