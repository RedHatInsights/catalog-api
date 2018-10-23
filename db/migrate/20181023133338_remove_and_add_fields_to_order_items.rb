class RemoveAndAddFieldsToOrderItems < ActiveRecord::Migration[5.1]
  def change
    remove_column :order_items, :parameters, :string
    remove_column :order_items, :plan_id, :string
    remove_column :order_items, :catalog_id, :string
    remove_column :order_items, :provider_id, :string
    add_column :order_items, :service_plan_ref, :string
    add_column :order_items, :portfolio_item_id, :bigint
    add_column :order_items, :service_parameters, :jsonb
    add_column :order_items, :provider_control_parameters, :jsonb
  end
end
