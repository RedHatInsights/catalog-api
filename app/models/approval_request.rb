class ApprovalRequest < ApplicationRecord
  acts_as_tenant(:tenant)
  validates :workflow_ref, :presence => true
  enum :state => [:undecided, :approved, :denied]

  belongs_to :order_item

  scope :by_owner, lambda {
    joins(:order_item)
      .select("approval_requests.*, order_items.owner")
      .where("order_items.owner = ?", ManageIQ::API::Common::Request.current.user.username)
  }
end
