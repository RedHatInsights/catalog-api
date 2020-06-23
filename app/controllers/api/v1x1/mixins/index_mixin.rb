module Api
  module V1x1
    module Mixins
      module IndexMixin
        include Api::V1x0::Mixins::IndexMixin

        def collection(base_query, pre_authorized: false)
          render :json => Insights::API::Common::PaginatedResponse.new(
            :base_query => filtered(scoped(base_query, pre_authorized)),
            :request    => request,
            :limit      => pagination_limit,
            :offset     => pagination_offset,
            :sort_by    => query_sort_by
          ).response
        end
      end
    end
  end
end
