module Catalog
  class CreateIcon
    attr_reader :icon

    def initialize(args)
      @content = Base64.strict_encode64(File.read(args.delete(:content).tempfile))
      @params = args

      if args.key?(:portfolio_item_id)
        @destination = PortfolioItem.find(args.delete(:portfolio_item_id))
      elsif args.key?(:portfolio_id)
        @destination = Portfolio.find(args.delete(:portfolio_id))
      end
    end

    def process
      image = Image.new(:content => @content)
      image_id = Catalog::DuplicateImage.new(image).process.image_id

      @destination.icon&.discard
      @icon = Icon.create!(@params.merge(:image_id => image_id, :restore_to => @destination))

      @destination.icon = @icon
      @destination.save!

      self
    end
  end
end
