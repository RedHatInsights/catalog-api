module Api
  module V0x1
    module Mixins
      module IndexMixin
        def list_order_items
          collection(scoped(Order.find(params.require(:order_id)).order_items, OrderItem))
        end

        def list_orders
          collection(scoped(Order.all, Order))
        end

        def list_portfolios
          collection(scoped(Portfolio.all, Portfolio))
        end

        def list_portfolio_items
          collection(scoped(PortfolioItem.all, PortfolioItem))
        end

        def fetch_portfolio_items_with_portfolio
          collection(scoped(Portfolio.find(params.require(:portfolio_id)).portfolio_items, PortfolioItem))
        end

        def list_progress_messages
          collection(scoped(OrderItem.find(params.require(:order_item_id)).progress_messages, ProgressMessage))
        end

        def scoped(relation, model)
          if model.respond_to?(:taggable?) && model.taggable?
            ref_schema = {model.tagging_relation_name => :tag}

            relation = relation.includes(ref_schema).references(ref_schema)
          end
          relation
        end

        def collection(base_query)
          render :json => ManageIQ::API::Common::PaginatedResponse.new(
            :base_query => base_query,
            :request    => request,
            :limit      => params.permit(:limit)[:limit],
            :offset     => params.permit(:offset)[:offset]
          ).response
        end
      end
    end
  end
end
