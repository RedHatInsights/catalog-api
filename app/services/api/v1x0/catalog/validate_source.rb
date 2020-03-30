module Api
  module V1x0
    module Catalog
      class ValidateSource
        attr_reader :valid

        def initialize(source_id)
          @source_id = source_id
        end

        def process
          @valid = sources.include?(@source_id)
          self
        end

        private

        def sources
          sources_api_call.data.map(&:id)
        end

        def sources_api_call
          Sources.call do |api_instance|
            api_instance.list_application_type_sources(catalog_id)
          end
        end

        def catalog_id
          Sources.call do |api_instance|
            name = ENV['APP_NAME'] || "catalog"
            api_instance.list_application_types.data.select { |type| type.name.split("/").last == name }.first&.id
          end
        end
      end
    end
  end
end
