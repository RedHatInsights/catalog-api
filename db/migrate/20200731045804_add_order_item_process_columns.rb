class AddOrderItemProcessColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :process_sequence, :integer
    add_column :order_items, :process_scope, :string
  end
end
