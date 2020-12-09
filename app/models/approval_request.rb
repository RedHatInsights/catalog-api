class ApprovalRequest < ApplicationRecord
  acts_as_tenant(:tenant)
  enum :state => [:undecided, :approved, :denied, :canceled, :error]

  belongs_to :order_item

  after_create do
    order_item.order.update_message("info", "Created Approval Request ref: #{approval_request_ref}.  catalog approval request id: #{id}")
  end

  scope :by_owner, lambda {
    joins("INNER JOIN order_items ON (order_items.id = approval_requests.order_item_id::int)")
      .joins("INNER JOIN orders ON (orders.id = order_items.order_id::int)")
      .where("orders.owner = ?", Insights::API::Common::Request.current.user.username)
  }
end
