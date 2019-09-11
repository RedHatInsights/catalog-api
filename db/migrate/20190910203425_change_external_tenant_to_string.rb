class ChangeExternalTenantToString < ActiveRecord::Migration[5.2]
  def up
    change_column :tenants, :external_tenant, :string
  end

  def down
    change_column :tenants, :external_tenant, "integer USING CAST(external_tenant AS integer)"
  end
end
