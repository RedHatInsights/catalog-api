class Icon < ApplicationRecord
  acts_as_tenant(:tenant)
  include Discard::Model
  default_scope -> { kept }

  belongs_to :portfolio_item
  validates :image_id, :presence => true

  def image
    Image.find(image_id)
  end
end
