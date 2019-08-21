class RenameOrderedAtColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :orders, :ordered_at, :order_request_sent_at
    rename_column :order_items, :ordered_at, :order_request_sent_at
  end
end
