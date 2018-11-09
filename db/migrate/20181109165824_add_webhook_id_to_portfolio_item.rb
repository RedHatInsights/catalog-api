class AddWebhookIdToPortfolioItem < ActiveRecord::Migration[5.1]
  def change
    add_column :portfolio_items, :pre_provision_webhook_id, :bigint
    add_column :portfolio_items, :post_provision_webhook_id, :bigint
  end
end
