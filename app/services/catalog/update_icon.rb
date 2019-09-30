module Catalog
  class UpdateIcon
    attr_reader :icon

    def initialize(icon_id, params)
      @icon = Icon.find(icon_id)
      @params = params

      if params.key?(:portfolio_item_id)
        PortfolioItem.find(params.delete(:portfolio_item_id)).icon = @icon
      elsif params.key?(:portfolio_id)
        Portfolio.find(params.delete(:portfolio_id)).icon = @icon
      end
    end

    def process
      update_image if @params.key?(:content)
      @icon.update!(@params)

      self
    end

    private

    def update_image
      content = Base64.strict_encode64(File.read(@params.delete(:content).tempfile))
      new_image = Image.new(:content => content)
      image_id = Catalog::DuplicateImage.new(new_image).process.image_id
      @icon.image.destroy unless @icon.image.icons.count > 1

      @params[:image_id] = image_id
    end
  end
end
