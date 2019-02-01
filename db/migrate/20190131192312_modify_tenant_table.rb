class ModifyTenantTable < ActiveRecord::Migration[5.2]
  def change
    rename_column :tenants, :ref_id, :external_tenant
    add_column :tenants, :name, :string
    add_column :tenants, :description, :string
  end
end
