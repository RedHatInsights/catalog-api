class AddServiceOfferingTypeToPortfolioItem < ActiveRecord::Migration[5.2]
  def change
    add_column :portfolio_items, :service_offering_type, :string
  end
end
