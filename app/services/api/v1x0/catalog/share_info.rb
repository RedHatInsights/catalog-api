module Api
  module V1x0
    module Catalog
      class ShareInfo
        attr_reader :result
        MAX_GROUPS_LIMIT = 500

        def initialize(options)
          @object = options[:object]
          @user_context = options[:user_context]
        end

        def process
          group_permissions = {}
          uuids = @object.access_control_entries.collect do |ace|
            group_permissions[ace.group_uuid] = ace.permissions.map(&:name)
            ace.group_uuid
          end

          group_names = @user_context.group_names(uuids)
          @result = group_permissions.each_with_object([]) do |(uuid, permissions), memo|
            next if permissions.empty?

            if group_names.key?(uuid)
              memo << { :group_name => group_names[uuid], :group_uuid => uuid, :permissions => permissions }
            else
              Rails.logger.warn("Skipping group UUID: #{uuid} since its missing from RBAC service")
            end

          end

          self
        end

      end
    end
  end
end
