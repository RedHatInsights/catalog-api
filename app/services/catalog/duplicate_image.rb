require 'fileutils'
require 'dhash'

module Catalog
  class DuplicateImage
    attr_reader :image_id

    def initialize(image)
      @count = 0
      @image = image
      @extension = @image.extension
      @og_path = write(image)
    end

    def process
      images = Image.where(:extension => @extension, :tenant_id => @image.tenant_id)

      if images.any? { |image| match?(image) }
        @image_id = @match.id
      else
        @image.save!
        @image_id = @image.id
      end

      cleanup
      self
    end

    private

    def match?(image)
      case @extension
      when "svg"
        @match = image if @image.content == image.content
      when "jpg", "png"
        hash1 = Dhash.calculate(@og_path)
        hash2 = Dhash.calculate(write(image))

        @match = image if Dhash.hamming(hash1, hash2) < 10
      end

      @match.present?
    end

    def write(image)
      File.open(Rails.root.join("tmp", "#{@count}.#{@extension}"), "w") do |fh|
        fh.write(image.content)
      end

      "#{@count += 1}.#{@extension}"
    end

    def cleanup
      (0..@count).each { |num| FileUtils.rm_f(Rails.root.join("tmp", "#{num}.#{@extension}")) }
    end
  end
end
