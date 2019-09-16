class Order < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Catalog::DiscardRestore
  destroy_dependencies :order_items
  acts_as_tenant(:tenant)

  default_scope { kept.order(:created_at => :desc) }

  has_many :order_items, :dependent => :destroy

  before_create :set_defaults

  def set_defaults
    self.state = "Created"
  end
end
