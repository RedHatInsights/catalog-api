class AddInsightsRequestIdToOrderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :insights_request_id, :string
  end
end
