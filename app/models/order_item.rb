class OrderItem < ApplicationRecord
  include OwnerField
  acts_as_tenant(:tenant)

  validates_presence_of :count
  validates_presence_of :service_parameters
  validates_presence_of :provider_control_parameters
  validates_presence_of :order_id
  validates_presence_of :service_plan_ref
  validates_presence_of :portfolio_item_id

  belongs_to :order
  belongs_to :portfolio_item
  has_many :progress_messages
  has_many :approval_requests, :dependent => :destroy
  before_create :set_defaults

  AS_JSON_ATTRIBUTES = %w(id order_id service_plan_ref portfolio_item_id state service_parameters external_url
                          provider_control_parameters external_ref created_at ordered_at completed_at updated_at).freeze

  def as_json(_options = {})
    super.slice(*AS_JSON_ATTRIBUTES)
  end

  def set_defaults
    self.state = "Created"
    self.context = ManageIQ::API::Common::Request.current.to_h
  end

  def update_message(level, message)
    progress_messages << ProgressMessage.new(:level => level, :message => message, :tenant_id => self.tenant_id)
    touch
  end
end
