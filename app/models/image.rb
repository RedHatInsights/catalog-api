class Image < ApplicationRecord
  XML_HEADER = "<?xml version=\"1.0\"?>".freeze
  MAX_IMAGE_SIZE = 250.kilobytes
  acts_as_tenant(:tenant)

  validates :content, :presence => true
  validates :extension,
            :presence  => true,
            :inclusion => { :in => %w[PNG JPEG SVG], :message => 'must be a PNG, JPEG, or SVG' }
  validate :image_size

  has_many :icons, :dependent => :nullify

  after_initialize :set_image_data_from_content, :if => proc { hashcode.nil? && content.present? }

  def set_image_data_from_content
    begin
      self.extension = Magick::Image.from_blob(decoded_image).first&.format
    rescue StandardError
      Rails.logger.debug("Bad image data, trying again with xml header added...")
      self.extension = Magick::Image.from_blob(XML_HEADER + decoded_image).first&.format
    end

    self.hashcode = case extension
                    when "SVG"
                      Digest::MD5.hexdigest(decoded_image)
                    when "JPEG", "PNG"
                      DHasher.hash_from_blob(decoded_image)
                    end
  end

  def decoded_image
    @decoded_image ||= Base64.decode64(content)
  end

  private

  def image_size
    if decoded_image.bytes.count > MAX_IMAGE_SIZE
      raise Catalog::InvalidParameter, "Image size exceeds max limit of #{MAX_IMAGE_SIZE.to_s(:human_size)}"
    end
  end
end
