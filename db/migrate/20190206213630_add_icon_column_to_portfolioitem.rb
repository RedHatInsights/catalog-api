class AddIconColumnToPortfolioitem < ActiveRecord::Migration[5.2]
  def change
    add_column :portfolio_items, :service_offering_icon_ref, :bigint
  end
end
