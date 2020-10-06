class AddAncillaryMetadataToPortfolioItem < ActiveRecord::Migration[5.2]
  def change
    PortfolioItem.all.each(&:update_metadata)
  end
end
