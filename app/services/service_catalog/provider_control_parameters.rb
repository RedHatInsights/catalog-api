module ServiceCatalog
  class ProviderControlParameters
    attr_reader :data
    def initialize(portfolio_item_id)
      @portfolio_item_id = portfolio_item_id
      @data = {}
    end

    def process
      source_ref = PortfolioItem.find(@portfolio_item_id).service_offering_source_ref
      TopologicalInventory.call do |api_instance|
        # TODO: Temporay till we get this call in the topology service
        projects = api_instance.list_source_container_projects(source_ref).data
        update_project_list(projects.collect(&:name))
        self
      end
    rescue StandardError => e
      Rails.logger.error("ProviderControlParameters #{e.message}")
      raise
    end

    private

    def update_project_list(projects)
      @data = JSON.parse(read_control_parameters)
      @data['properties']['namespace']['enum'] = projects
    end

    def read_control_parameters
      # TODO: This belongs in the topology service, temporarily hosting it in service portal
      File.read(Rails.root.join("schemas", "json", "openshift_control_parameters.json"))
    end
  end
end
