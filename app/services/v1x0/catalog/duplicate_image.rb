require 'fileutils'
require 'dhasher'

module V1x0
  module Catalog
    class DuplicateImage
      attr_reader :image_id

      def initialize(image)
        @new_image = image
        @extension = image.extension
      end

      def process
        images = Image.where(:extension => @extension, :tenant_id => @new_image.tenant_id)

        if images.any? { |image| match?(image) }
          @image_id = @match.id
        else
          @new_image.save!
          @image_id = @new_image.id
        end

        self
      end

      private

      def match?(image)
        case @extension
        when "SVG"
          @match = image if @new_image.hashcode == image.hashcode
        when "JPEG", "PNG"
          @match = image if DHasher.similar?(@new_image.hashcode.to_i, image.hashcode.to_i)
        end

        @match.present?
      end
    end
  end
end
