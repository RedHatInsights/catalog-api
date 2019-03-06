module ServiceOffering
  class Icons
    attr_reader :icon_id
    attr_reader :icon

    def initialize(id)
      @icon_id = id.to_s
    end

    def process
      TopologicalInventory.call do |api|
        @icon = api.show_service_offering_icon(@icon_id)
      end

      self
    rescue StandardError => e
      Rails.logger.error("Portfolio Item Icons ID #{@icon_id}: #{e.message}")
      raise
    end
  end
end
