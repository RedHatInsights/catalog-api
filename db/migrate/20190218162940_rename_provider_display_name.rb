class RenameProviderDisplayName < ActiveRecord::Migration[5.2]
  def change
    rename_column :portfolio_items, :provider_display_name, :distributor
  end
end
