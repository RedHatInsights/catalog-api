module Catalog
  class CreateIcon
    attr_reader :icon

    def initialize(args)
      @extension = args.delete(:filename).split(".").last
      @content = args.delete(:content)
      @params = args
    end

    def process
      image = Image.create!(:extension => @extension, :content => image_content)
      @icon = Icon.create!(@params.merge(:image_id => image.id))

      self
    end

    private

    def image_content
      @extension == "svg" ? @content : Base64.decode64(@content)
    end
  end
end
