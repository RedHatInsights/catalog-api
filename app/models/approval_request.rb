class ApprovalRequest < ApplicationRecord
  acts_as_tenant(:tenant)
  validates :workflow_ref, :presence => true
  enum :state => [:undecided, :approved, :denied, :canceled]

  belongs_to :order_item

  scope :by_owner, lambda {
    joins("INNER JOIN order_items ON (order_items.id = approval_requests.order_item_id::int)")
      .joins("INNER JOIN orders ON (orders.id = order_items.order_id::int)")
      .where("orders.owner = ?", ManageIQ::API::Common::Request.current.user.username)
  }
end
