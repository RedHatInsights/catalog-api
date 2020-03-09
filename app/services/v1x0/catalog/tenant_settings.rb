module V1x0
  module Catalog
    class TenantSettings
      attr_reader :response

      def initialize(tenant)
        @tenant = tenant
      end

      def process
        @response = {
          :current => @tenant.settings,
          :schema  => JSON.parse(schema)
        }

        self
      end

      private

      def schema
        @schema ||= File.read(Rails.root.join("schemas", "json", "tenant_settings.json"))
      end
    end
  end
end
