class AddReturnPortfolioItemIdToOrderProcesses < ActiveRecord::Migration[5.2]
  def change
    add_column :order_processes, :return_portfolio_item_id, :integer
  end
end
