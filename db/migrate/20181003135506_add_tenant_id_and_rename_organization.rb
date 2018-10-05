class AddTenantIdAndRenameOrganization < ActiveRecord::Migration[5.1]
  def change
    rename_table :organizations, :tenants
    add_column :tenants, :ref_id, :bigint
    add_index :tenants, :ref_id

    add_column :portfolios, :tenant_id, :bigint
    add_index  :portfolios, :tenant_id

    add_column :portfolio_items, :tenant_id, :bigint
    add_index  :portfolio_items, :tenant_id

    add_column :orders, :tenant_id, :bigint
    add_index  :orders, :tenant_id

    add_column :order_items, :tenant_id, :bigint
    add_index  :order_items, :tenant_id

    add_column :progress_messages, :tenant_id, :bigint
    add_index  :progress_messages, :tenant_id
  end
end
