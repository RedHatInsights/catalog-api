class Order < ApplicationRecord
  include OwnerField
  acts_as_tenant(:tenant)

  default_scope { order(:created_at => :desc) }

  has_many :order_items

  before_create :set_defaults

  def set_defaults
    self.state = "Created"
  end
end
