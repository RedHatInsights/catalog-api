class Icon < ApplicationRecord
  acts_as_tenant(:tenant)
  include Discard::Model
  default_scope -> { kept }

  belongs_to :iconable, :polymorphic => true
  belongs_to :image
  validates :image_id, :presence => true
end
