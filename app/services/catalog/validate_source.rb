module Catalog
  class ValidateSource
    attr_reader :valid

    def initialize(portfolio_item_id)
      @portfolio_item = PortfolioItem.find(portfolio_item_id)
    end

    def process
      @valid = sources.include?(@portfolio_item.service_offering_source_ref)
      self
    end

    private

    def sources
      api_call.data.map(&:id)
    end

    def api_call
      Sources::Service.call(SourcesApiClient::DefaultApi) do |api_instance|
        # api_instance.list_sources_by_application_type(id)
        api_instance.list_application_types
      end
    end
  end
end
