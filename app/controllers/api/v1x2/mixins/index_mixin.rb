module Api
  module V1x2
    module Mixins
      module IndexMixin
        include Api::V1x1::Mixins::IndexMixin

        def permitted_params
          super + [:object_type, :object_id, :app_name]
        end
      end
    end
  end
end
