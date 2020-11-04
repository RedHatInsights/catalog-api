module Api
  module V1x3
    module Mixins
      module IndexMixin
        include Api::V1x2::Mixins::IndexMixin

        def permitted_params
          check_if_openapi_enabled
          api_doc_definition.all_attributes + [:limit, :offset, :sort_by, :object_type, :object_id, :app_name, :source_type] + [subcollection_foreign_key]
        end
      end
    end
  end
end
