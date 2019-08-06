class Image < ApplicationRecord
  acts_as_tenant(:tenant)

  validates :content, :presence => true
  validates :extension,
            :presence  => true,
            :inclusion => { :in => %w[png jpg svg], :message => 'must be a png, jpg, or svg' }

  validate :uniqe_image

  def uniqe_image
    Image.all.any? do |image|
      # TODO: find best way to hash through all images and compare duplications
    end
  end
end
