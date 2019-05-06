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

  def transition_state
    update!(:state => determine_order_state)
  end

  private

  def determine_order_state
    item_states = order_items.collect(&:state)

    if item_states.include?('Failed')
      'Failed'
    elsif item_states.include?('Denied')
      'Denied'
    elsif item_states.all? { |state| state == "Approved" }
      'Approved'
    elsif item_states.all? { |state| state == "Completed" }
      'Completed'
    else
      'Ordered'
    end
  end
end
