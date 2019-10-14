class AddRequestCompletedAtToApprovalRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :approval_requests, :request_completed_at, :datetime
  end
end
