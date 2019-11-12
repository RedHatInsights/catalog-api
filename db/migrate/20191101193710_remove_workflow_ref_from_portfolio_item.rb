class RemoveWorkflowRefFromPortfolioItem < ActiveRecord::Migration[5.2]
  def change
    remove_column :portfolio_items, :workflow_ref, :string
    remove_column :approval_requests, :workflow_ref, :string
    remove_column :portfolios, :workflow_ref, :string
  end
end
