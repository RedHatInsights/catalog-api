class AddStatisticsToPortfolio < ActiveRecord::Migration[5.2]
  def change
    add_column :portfolios, :statistics, :jsonb, :default => {}

    reversible do |change|
      change.up do
        Portfolio.all.each(&:update_statistics)
      end
    end
  end
end
