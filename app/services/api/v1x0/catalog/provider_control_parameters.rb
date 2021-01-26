module Api
  module V1x0
    module Catalog
      class ProviderControlParameters
        include ::Catalog::JsonSchemaReader

        attr_reader :data

        def initialize(portfolio_item_id)
          @portfolio_item_id = portfolio_item_id
        end

        # TODO: empty now, need to decide what we should do for openshift
        def process
          self
        end

        private

        def update_project_list(projects)
          @project_names = projects.collect(&:name).sort
          @data = read_json_schema("openshift_control_parameters.erb")
        end
      end
    end
  end
end
