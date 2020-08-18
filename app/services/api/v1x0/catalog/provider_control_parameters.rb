module Api
  module V1x0
    module Catalog
      class ProviderControlParameters
        include ::Catalog::JsonSchemaReader

        attr_reader :data

        def initialize(portfolio_item_id)
          @portfolio_item_id = portfolio_item_id
        end

        def process
          source_ref = PortfolioItem.find(@portfolio_item_id).service_offering_source_ref
          TopologicalInventory::Service.call do |api_instance|
            # TODO: Temporay till we get this call in the topology service
            projects = api_instance.list_source_container_projects(source_ref).data
            update_project_list(projects)
            self
          end
        rescue StandardError => e
          Rails.logger.error("ProviderControlParameters #{e.message}")
          raise
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
