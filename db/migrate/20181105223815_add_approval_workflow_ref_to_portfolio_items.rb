class AddApprovalWorkflowRefToPortfolioItems < ActiveRecord::Migration[5.1]
  def change
    add_column :portfolio_items, :approval_workflow_ref, :string
  end
end
