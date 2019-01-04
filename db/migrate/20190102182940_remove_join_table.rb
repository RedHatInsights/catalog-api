class RemoveJoinTable < ActiveRecord::Migration[5.1]
  class PortfolioItem < ActiveRecord::Base
    has_and_belongs_to_many :portfolios
  end

  class Portfolio < ActiveRecord::Base
    has_and_belongs_to_many :portfolio_items
  end

  def up
    add_column :portfolio_items, :portfolio_id, :bigint

    PortfolioItem.all.each do |portfolio_item|
      portfolio_item.update_attribute('portfolio_id', portfolio_item.portfolios.first.id) if portfolio_item.portfolios.present?
    end

    drop_join_table :portfolios, :portfolio_items
  end

  def down
    create_join_table :portfolios, :portfolio_items do |t|
      t.index [:portfolio_id, :portfolio_item_id], name: 'index_items_on_portfolio_id_and_portfolio_item_id'
      t.index [:portfolio_item_id, :portfolio_id], name: 'index_items_on_portfolio_item_id_and_portfolio_id'
    end

    PortfolioItem.all.each do |portfolio_item|
      portfolio_item.portfolios << Portfolio.find(portfolio_item.portfolio_id) if portfolio_item.portfolio_id
    end

    remove_column :portfolio_items, :portfolio_id
  end
end
