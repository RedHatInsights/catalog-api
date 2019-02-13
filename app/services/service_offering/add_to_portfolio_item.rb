module ServiceOffering
  class AddToPortfolioItem
    IGNORE_FIELDS = %w(id created_at updated_at portfolio_id).freeze

    attr_reader :params
    attr_reader :item

    def initialize(params)
      @params = HashWithIndifferentAccess.new(params)
    end

    def process
      # Get the api response object from Topology
      TopologicalInventory.call do |api_instance|
        @service_offering = api_instance.show_service_offering(@params[:service_offering_ref])
      end

      # Get the fields that we're going to pull over
      create_param_map(determine_valid_fields)

      @item = PortfolioItem.create!(populate_missing_fields)
      self
    rescue StandardError => e
      Rails.logger.error("Service Offering Ref: #{@params[:service_offering_ref]} #{e.message}")
      raise
    end

    private

    def determine_valid_fields
      # These are the fields that topology gave us, so we want to pull them into our model.
      # Along the way we map them to their string counterparts, then reject the columsn we don't need
      @service_offering.instance_variables
                       .map { |var| var.to_s.delete("@") }
                       .reject { |field| IGNORE_FIELDS.include?(field) }
    end

    # Move fields from the ServiceOffering Ojbect to our params hash, from which we build our PortfolioItem
    def create_param_map(fields)
      # logical AND the column names with the fields we know we have, so we only pull in what is available
      (PortfolioItem.column_names & fields).each do |column|
        @params[column] = @service_offering.instance_variable_get("@" + column)
      end
    end

    # If certain fields are empty populate them from the other fields that we do have.
    def populate_missing_fields
      @params[:service_offering_source_ref] = @service_offering.instance_variable_get("@source_ref")
      # Fill up empty fields if they're empty with fields we already have, this is really easy with the ||= and subsequent || operators
      @params[:long_description] ||= @params[:description] || @params[:display_name]
      @params[:display_name] ||= @params[:name]
      @params
    end
  end
end
