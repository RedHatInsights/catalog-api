class Icon < ApplicationRecord
  acts_as_tenant(:tenant)
  include Discard::Model
  default_scope -> { kept }

  belongs_to :image
  belongs_to :restore_to, :polymorphic => true

  has_one :portfolio, :dependent => :destroy
  has_one :portfolio_item, :dependent => :destroy

  validates :image_id, :presence => true

  after_discard do
    restore_to.update!(:icon_id => nil)
  end
end
