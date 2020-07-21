class AddAfterPortfolioItemIdToOrderProcesses < ActiveRecord::Migration[5.2]
  def change
    add_column :order_processes, :after_portfolio_item_id, :integer
  end
end
