class AddApprovalRequestRefToOrderItems < ActiveRecord::Migration[5.1]
  def change
    add_column :order_items, :approval_request_ref, :string
  end
end
