class AddContextToOrderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :context, :jsonb
  end
end
