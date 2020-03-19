class AddServiceInstanceRefToOrderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :service_instance_ref, :string
  end
end
