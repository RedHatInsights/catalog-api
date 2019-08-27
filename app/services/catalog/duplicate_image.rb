require 'fileutils'
require 'dhasher'

module Catalog
  class DuplicateImage
    attr_reader :image_id

    def initialize(image)
      @new_image = image
      @extension = @new_image.extension
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
      when "svg"
        @match = image if @new_image.content == image.content
      when "jpg", "png"
        hash1 = DHasher.hash_from_blob(raw_image(@new_image.content))
        hash2 = DHasher.hash_from_blob(raw_image(image.content))

        @match = image if DHasher.similar?(hash1, hash2)
      end

      @match.present?
    end

    def raw_image(encoded_content)
      Base64.decode64(encoded_content)
    end
  end
end
