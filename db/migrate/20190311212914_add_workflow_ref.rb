class AddWorkflowRef < ActiveRecord::Migration[5.2]
  def change
    add_column :portfolios, :workflow_ref, :string
  end
end
