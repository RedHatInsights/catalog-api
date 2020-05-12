module Api
  module V1x0
    module Mixins
      module ShowMixin
        def show
          instance = model.find(params.require(:id))
          authorize(instance)

          render :json => instance
        end
      end
    end
  end
end
