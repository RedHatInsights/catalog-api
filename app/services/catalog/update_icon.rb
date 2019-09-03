module Catalog
  class UpdateIcon
    attr_reader :icon

    def initialize(icon_id, params)
      @icon = Icon.find(icon_id)
      @params = params
    end

    def process
      update_image if @params.key?(:content)
      @icon.update!(@params)

      self
    end

    private

    def update_image
      new_image = Image.new(:content => @params.delete(:content))
      image_id = Catalog::DuplicateImage.new(new_image).process.image_id
      @icon.image.destroy unless @icon.image.icons.count > 1

      @params[:image_id] = image_id
    end
  end
end
