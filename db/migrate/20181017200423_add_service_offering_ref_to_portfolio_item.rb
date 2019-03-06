class AddServiceOfferingRefToPortfolioItem < ActiveRecord::Migration[5.1]
  def change
    say_with_time "Removing all PortfolioItems, adding a new required field: service_offerings_ref" do
      PortfolioItem.unscoped.delete_all
    end
    add_column :portfolio_items, :service_offering_ref, :string
  end
end
