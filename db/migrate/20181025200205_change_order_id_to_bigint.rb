class ChangeOrderIdToBigint < ActiveRecord::Migration[5.1]
  def up
    change_column :order_items, :order_id, 'bigint using order_id::bigint'
  end

  def down
    change_column :order_items, :order_id, :string
  end
end
