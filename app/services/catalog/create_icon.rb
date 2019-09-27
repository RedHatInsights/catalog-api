module Catalog
  class CreateIcon
    attr_reader :icon

    def initialize(args)
      @content = Base64.strict_encode64(File.read(args.delete(:content).tempfile))
      @params = args
    end

    def process
      image = Image.new(:content => @content)
      image_id = Catalog::DuplicateImage.new(image).process.image_id

      @icon = Icon.create!(@params.merge(:image_id => image_id))

      self
    end
  end
end
