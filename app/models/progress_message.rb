class ProgressMessage < ApplicationRecord
  acts_as_tenant(:tenant)

  after_initialize :set_defaults, unless: :persisted?

  scope :by_owner, lambda {
    joins("INNER JOIN order_items ON (order_items.id = progress_messages.order_item_id::int)")
      .joins("INNER JOIN orders ON (orders.id = order_items.order_id::int)")
      .where("orders.owner = ?", ManageIQ::API::Common::Request.current.user.username)
  }

  def set_defaults
    self.received_at = DateTime.now
  end
end
