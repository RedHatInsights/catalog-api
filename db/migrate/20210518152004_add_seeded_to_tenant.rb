class AddSeededToTenant < ActiveRecord::Migration[5.2]
  def change
    add_column :tenants, :seeded, :boolean, default: false
  end
end
