class AddSettingsToTenant < ActiveRecord::Migration[5.2]
  def change
    add_column :tenants, :settings, :jsonb
  end
end
