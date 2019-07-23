class OrderItem < ApplicationRecord
  include OwnerField
  acts_as_tenant(:tenant)

  validates_presence_of :count
  validates_presence_of :service_parameters
  validates_presence_of :order_id
  validates_presence_of :service_plan_ref
  validates_presence_of :portfolio_item_id

  belongs_to :order
  belongs_to :portfolio_item
  has_many :progress_messages
  has_many :approval_requests, :dependent => :destroy
  before_create :set_defaults

  def set_defaults
    self.state = "Created"

    if ManageIQ::API::Common::Request.current.present?
      self.context = ManageIQ::API::Common::Request.current.to_h
      self.insights_request_id = ManageIQ::API::Common::Request.current.request_id
    end
  end

  def update_message(level, message)
    progress_messages << ProgressMessage.new(:level => level, :message => message, :tenant_id => self.tenant_id)
    touch
  end
end
