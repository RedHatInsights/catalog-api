class CreateApprovalRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :approval_requests do |t|
      t.string :approval_request_ref
      t.string :workflow_ref
      t.string :state, :default => "undecided"
      t.integer :order_item_id

      t.timestamps
    end
  end
end
