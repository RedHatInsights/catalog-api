class ChangeApprovalStateColumnType < ActiveRecord::Migration[5.2]
  def up
    remove_column :approval_requests, :state
    add_column :approval_requests, :state, :integer, :default => 0
  end

  def down
    change_column :approval_requests, :state, :string, :default => "0"
  end
end
