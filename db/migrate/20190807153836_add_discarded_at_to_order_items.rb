class AddDiscardedAtToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :discarded_at, :datetime
    add_index :order_items, :discarded_at
  end
end
