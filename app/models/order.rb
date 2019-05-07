class Order < ApplicationRecord
  include OwnerField
  acts_as_tenant(:tenant)

  default_scope { order(:created_at => :desc) }

  has_many :order_items

  before_create :set_defaults

  AS_JSON_ATTRIBUTES = %w[id state owner created_at ordered_at completed_at].freeze

  def as_json(_options = {})
    super.slice(*AS_JSON_ATTRIBUTES)
  end

  def set_defaults
    self.state = "Created"
  end
end
