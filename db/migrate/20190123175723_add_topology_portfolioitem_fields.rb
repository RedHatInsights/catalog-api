class AddTopologyPortfolioitemFields < ActiveRecord::Migration[5.2]
  def change
    add_column :portfolio_items, :display_name, :string
    add_column :portfolio_items, :long_description, :string
    add_column :portfolio_items, :provider_display_name, :string
    add_column :portfolio_items, :documentation_url, :string
    add_column :portfolio_items, :support_url, :string
  end
end
