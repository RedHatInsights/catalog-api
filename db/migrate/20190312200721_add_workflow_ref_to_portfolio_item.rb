class AddWorkflowRefToPortfolioItem < ActiveRecord::Migration[5.2]
  def change
    add_column :portfolio_items, :workflow_ref, :string
  end
end
