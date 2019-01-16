class AddServiceOfferingSourceRefToPortfolioItems < ActiveRecord::Migration[5.1]
  def change
    add_column :portfolio_items, :service_offering_source_ref, :string
  end
end
