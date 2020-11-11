class AddNameToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :name, :string
  end
end
