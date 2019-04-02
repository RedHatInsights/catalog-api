class AddTenantToApprovalRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :approval_requests, :tenant_id, :bigint
    add_index :approval_requests, :tenant_id
  end
end
