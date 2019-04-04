module ServiceOffering
  class AddToPortfolioItem
    IGNORE_FIELDS = %w(id created_at updated_at portfolio_id tenant_id).freeze

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
      @item = PortfolioItem.create!(generate_attributes)
      self
    rescue StandardError => e
      Rails.logger.error("Service Offering Ref: #{@params[:service_offering_ref]} #{e.message}")
      raise
    end

    private

    def creation_fields
      service_offering_columns = @service_offering.instance_variables.map { |x| x.to_s[1..-1] }
      portfolio_item_columns = PortfolioItem.column_names - IGNORE_FIELDS
      service_offering_columns & portfolio_item_columns
    end

    def generate_attributes
      creation_fields.each do |column|
        @params[column] = @service_offering.send(column) if @service_offering.send(column).present?
      end
      populate_missing_fields
    end

    # If certain fields are empty populate them from the other fields that we do have.
    def populate_missing_fields
      @params[:service_offering_source_ref] = @service_offering.source_id
      @params[:service_offering_icon_ref] = @service_offering.service_offering_icon_id
      # Fill up empty fields if they're empty with fields we already have, this is really easy with the ||= and subsequent || operators
      @params[:long_description] ||= @params[:description] || @params[:display_name]
      @params[:display_name] ||= @params[:name]
      @params
    end
  end
end
