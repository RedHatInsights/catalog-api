class RemovePortfolioItemDisployName < ActiveRecord::Migration[5.2]
  def change
    remove_column :portfolio_items, :display_name
  end
end
