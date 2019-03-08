class AddOwnersColumnToTenancyTables < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :owner, :string
    add_column :orders, :owner, :string
    add_column :portfolio_items, :owner, :string
    add_column :portfolios, :owner, :string
  end
end
