module Api
  module V1
    module Mixins
      module ValidationMixin
        def group_id_array_check(uuids)
          if !uuids.kind_of?(Array)
            invalid_parameter('Group should be an array')
          elsif uuids.blank? || uuids.any?(&:blank?)
            invalid_parameter('Group should not be empty')
          end
        end
      end
    end
  end
end
