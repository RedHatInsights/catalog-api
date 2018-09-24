class CreateJoinTablePortfolioPortfolioItem < ActiveRecord::Migration[5.1]
  def change
    create_join_table :portfolios, :portfolio_items do |t|
      t.index [:portfolio_id, :portfolio_item_id], name: 'index_items_on_portfolio_id_and_portfolio_item_id'
      t.index [:portfolio_item_id, :portfolio_id], name: 'index_items_on_portfolio_item_id_and_portfolio_id'
    end

    remove_column :portfolio_items, :portfolio_id
  end
end
