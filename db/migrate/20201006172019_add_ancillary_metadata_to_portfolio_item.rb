class AddAncillaryMetadataToPortfolioItem < ActiveRecord::Migration[5.2]
  def up
    PortfolioItem.all.each(&:update_metadata)
  end

  def down
    PortfolioItem.all.each do |portfolio_item|
      portfolio_item.metadata = {'user_capabilities' => portfolio_item.ancillary_metadata.metadata_attributes[:user_capabilities]}
      portfolio_item.ancillary_metadata.destroy
    end
  end
end
