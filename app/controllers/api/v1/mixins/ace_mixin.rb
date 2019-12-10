module Api
  module V1
    module Mixins
      module ACEMixin
        def ace_ids(verb, klass)
          permission = "#{ENV['APP_NAME']}:#{klass.table_name}:#{verb}"
          params = { :group_uuid => my_group_uuids, :permission => permission, :aceable_type => klass.to_s }
          AccessControlEntry.where(params).collect { |ace| ace.aceable_id.to_s }
        end

        def my_group_uuids
          @my_group_uuids ||= Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
            Insights::API::Common::RBAC::Service.paginate(api, :list_groups, :scope => 'principal').collect(&:uuid)
          end
        end
      end
    end
  end
end
