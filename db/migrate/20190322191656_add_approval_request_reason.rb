class AddApprovalRequestReason < ActiveRecord::Migration[5.2]
  def change
    add_column :approval_requests, :reason, :string
  end
end
