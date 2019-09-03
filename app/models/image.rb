class Image < ApplicationRecord
  acts_as_tenant(:tenant)

  validates :content, :presence => true
  validates :extension,
            :presence  => true,
            :inclusion => { :in => %w[PNG JPEG SVG], :message => 'must be a PNG, JPEG, or SVG' }

  has_many :icons, :dependent => :nullify

  after_initialize :set_image_data_from_content, :if => proc { hashcode.nil? && content.present? }

  def set_image_data_from_content
    self.extension = Magick::Image.from_blob(decoded_image).first&.format

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
end
