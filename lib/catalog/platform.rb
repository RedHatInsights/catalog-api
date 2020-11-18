module Catalog
  module Platform
    private

    def platform(portfolio_item)
      Sources.call do |api_instance|
        api_instance.show_source(portfolio_item.service_offering_source_ref)
      end
    end
  end
end
