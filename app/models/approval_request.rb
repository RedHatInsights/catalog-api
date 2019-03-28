class ApprovalRequest < ApplicationRecord
  validates :workflow_ref, :presence => true
  enum :state => [:undecided, :approved, :denied]

  belongs_to :order_item

  def approved?
    state == "approved"
  end

  def denied?
    state == "denied"
  end
end
