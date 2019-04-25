class Order < ApplicationRecord
  include OwnerField
  acts_as_tenant(:tenant)

  default_scope { order(:created_at => :desc) }

  has_many :order_items

  after_initialize :set_defaults, unless: :persisted?

  AS_JSON_ATTRIBUTES = %w(id state created_at ordered_at completed_at).freeze

  def as_json(_options = {})
    super.slice(*AS_JSON_ATTRIBUTES)
  end

  def set_defaults
    self.state = "Created"
  end

  def finalize_order
    item_states = order_items.collect(&:state)
    if item_states.include?('Failed')
      self.state = "Failed"
    elsif item_states.include?('Completed') && item_states.count == order_items.count
      self.state = 'Completed'
    else
      self.state = 'Ordered'
    end
    save!
  end
end
