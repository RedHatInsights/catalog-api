class AddBeforePortfolioItemIdToOrderProcesses < ActiveRecord::Migration[5.2]
  def change
    add_column :order_processes, :before_portfolio_item_id, :integer
  end
end
