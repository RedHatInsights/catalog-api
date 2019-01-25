module ServiceOffering
  class AddToPortfolioItem
    def initialize(params)
      @req_params = params
    end

    def process
      # Get the api response object from Topology
      TopologicalInventory.call do |api_instance|
        @service_offering = api_instance.show_service_offering(@req_params[:service_offering_ref])
      end

      params = HashWithIndifferentAccess.new
      # Ignore these fields because we don't want to persist them (because we set them or otherwise)
      ignore_fields = %w(id created_at updated_at portfolio_id)

      # These are the fields that topology gave us, so we want to pull them into our model.
      # Along the way we map them to their string counterparts, then reject the columsn we don't need
      fields_returned = @service_offering.instance_variables
                                         .map { |var| var.to_s.delete("@") }
                                         .reject { |field| ignore_fields.include?(field) }

      # Only set the columns that were returned, we'll do the autofill later.
      (PortfolioItem.column_names & fields_returned).each do |column|
        params[column] = @service_offering.instance_variable_get("@" + column)
      end

      params[:service_offering_ref] = @req_params[:service_offering_ref]
      params[:service_offering_source_ref] = @service_offering.source_ref

      # Populate missing fields if they're empty. Easy to set up backups with the ||= and subsequendt || operators
      params[:long_description] ||= params[:description] || params[:display_name]
      params[:display_name] ||= params[:name]

      PortfolioItem.create!(params)
    end
  end
end
