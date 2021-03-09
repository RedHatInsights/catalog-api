module Api
  module V1x0
    module Catalog
      class CopyPortfolioItem
        include IconMixin
        attr_reader :new_portfolio_item

        def initialize(params)
          @portfolio_item = PortfolioItem.find(params[:portfolio_item_id])
          @name = params[:portfolio_item_name] || @portfolio_item.name

          begin
            @to_portfolio = Portfolio.find(params[:portfolio_id] || @portfolio_item.portfolio_id)
          rescue ActiveRecord::RecordNotFound
            raise ::Catalog::InvalidParameter, "Portfolio specified not found"
          end
        end

        def process
          PortfolioItem.transaction do
            determine_orderable
            @new_portfolio_item = make_copy
          rescue => e
            Rails.logger.error("Failed to copy Portfolio Item #{@portfolio_item.id}: #{e.message}")
            raise
          end

          self
        end

        private

        def determine_orderable
          return if Api::V1x1::Catalog::PortfolioItemOrderable.new(@portfolio_item).process.result
          raise ::Catalog::OrderNotOrderable, "#{@portfolio_item.name} is not orderable, and cannot be copied"
        end

        def make_copy
          @portfolio_item.dup.tap do |new_portfolio_item|
            new_portfolio_item.name = new_name(@name)

            duplicate_icon(@portfolio_item, new_portfolio_item) if @portfolio_item.icon_id.present?

            @portfolio_item.service_plans.each do |plan|
              new_plan = plan.dup
              new_plan.save!
              new_portfolio_item.service_plans << new_plan
            end

            new_portfolio_item.portfolio_id = @to_portfolio.id

            new_portfolio_item.save
          end
        end

        def new_name(name)
          portfolio_names = @to_portfolio.portfolio_items.pluck(:name)
          if portfolio_names.include?(name)
            ::Catalog::NameAdjust.create_copy_name(name, portfolio_names, PortfolioItem::MAX_NAME_LENGTH)
          else
            name
          end
        end
      end
    end
  end
end
