class AddExternalUrlToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :external_url, :string
  end
end
