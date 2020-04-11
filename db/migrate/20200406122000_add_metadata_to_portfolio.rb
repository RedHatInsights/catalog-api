class AddMetadataToPortfolio < ActiveRecord::Migration[5.2]
  def change
    add_column :portfolios, :metadata, :jsonb, :default => {}

    reversible do |change|
      change.up do
        Portfolio.all.each(&:update_metadata)
      end
    end
  end
end
