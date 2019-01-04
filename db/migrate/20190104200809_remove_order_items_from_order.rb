class RemoveOrderItemsFromOrder < ActiveRecord::Migration[5.1]
  def change
    remove_column :orders, :order_items, :string
  end
end
