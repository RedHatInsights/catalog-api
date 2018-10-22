class ChangeIdsToBigint < ActiveRecord::Migration[5.1]
  def change
    change_column :catalog_items, :portfolio_item_id, :bigint

    %i{orders order_items portfolios portfolio_items progress_messages providers portfolios tenants}.each do |table|
      change_column table, :id, :bigint
    end
  end
end
