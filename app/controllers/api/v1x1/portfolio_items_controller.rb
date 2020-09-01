module Api
  module V1x1
    class PortfolioItemsController < Api::V1x0::PortfolioItemsController
      include Api::V1x1::Mixins::IndexMixin

      def show
        portfolio_item = model.find(params.require(:id))

        render_item(portfolio_item)
      end

      private

      def render_item(item, is_discarded = false)
        authorize(item)
        json = item.as_json(:prefixes => _prefixes, :template => action_name)
        json['metadata']['orderable'] = if is_discarded
                                          false
                                        else
                                          Catalog::PortfolioItemOrderable.new(item).process.result
                                        end

        render :json => json
      end
    end
  end
end
