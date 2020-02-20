class AddServiceParametersRaw < ActiveRecord::Migration[5.1]
  def change
    add_column :order_items, :service_parameters_raw, :jsonb

    OrderItem.update_all("service_parameters_raw=service_parameters")
  end
end
