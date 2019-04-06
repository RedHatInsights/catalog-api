class AddEnabledToTenant < ActiveRecord::Migration[5.2]
  def change
    add_column :tenants, :rbac_enabled, :boolean
  end
end
