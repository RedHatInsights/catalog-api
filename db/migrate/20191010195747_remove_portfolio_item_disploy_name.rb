class RemovePortfolioItemDisployName < ActiveRecord::Migration[5.2]
  def change
    remove_column :portfolio_items, :name, :string
    rename_column :portfolio_items, :display_name, :name
  end
end
