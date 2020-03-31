class Icon < ApplicationRecord
  acts_as_tenant(:tenant)
  include Discard::Model
  default_scope -> { kept }

  belongs_to :image
  belongs_to :restore_to, :polymorphic => true

  has_one :portfolio, :dependent => :nullify
  has_one :portfolio_item, :dependent => :nullify

  validates :image_id, :presence => true

  after_discard do
    restore_to.update!(:icon_id => nil)
  end
end
