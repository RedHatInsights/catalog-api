module Api
  module V1x0
    module Catalog
      class CopyPortfolio
        include IconMixin
        attr_reader :new_portfolio

        def initialize(params)
          @name = params[:portfolio_name]
          @portfolio = Portfolio.find(params[:portfolio_id])
        end

        def process
          @new_portfolio = make_copy

          self
        end

        private

        def make_copy
          Portfolio.transaction do
            @portfolio.dup.tap do |new_portfolio|
              new_portfolio.name = @name || ::Catalog::NameAdjust.create_copy_name(@portfolio.name, Portfolio.all.pluck(:name), Portfolio::MAX_NAME_LENGTH)

              duplicate_icon(@portfolio, new_portfolio) if @portfolio.icon_id.present?

              new_portfolio.save!

              copy_portfolio_items(new_portfolio.id)

              new_portfolio.update_metadata
            end
          end
        end

        def copy_portfolio_items(portfolio_id)
          @portfolio.portfolio_items.each do |item|
            Api::V1x0::Catalog::CopyPortfolioItem.new(:portfolio_item_id => item.id, :portfolio_id => portfolio_id).process
          rescue ::Catalog::OrderNotOrderable => e
            Rails.logger.error("Failed to copy Portfolio Item #{item.id}: #{e.message}")
          end
        end
      end
    end
  end
end
