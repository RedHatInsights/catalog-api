module ServiceOffering
  class Icons
    attr_reader :icon_ids
    attr_reader :icons

    def initialize(id)
      @icon_ids = id.to_s
    end

    def process
      @icons = @icon_ids.split(",").map do |id|
        TopologicalInventory.call do |api|
          api.show_service_offering_icon(id)
        end
      end

      self
    rescue StandardError => e
      Rails.logger.error("Portfolio Item Icons ID #{@icon_ids}: #{e.message}")
      raise
    end
  end
end
