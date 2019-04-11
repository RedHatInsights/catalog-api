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

  def monitor
    prov = Provider.find(provider_id)
    reason = "Provisioning"
    inflight = %w(Provisioning ProvisionRequestInFlight)
    parsed_data = {}
    while inflight.include?(reason) do
      sleep(5)
      response = prov.service_status(external_ref)
      parsed_data = JSON.parse(response.body)
      async = parsed_data['status']['asyncOpInProgress']

      message = parsed_data['status']['conditions'][0]['message']
      # puts "Status : #{parsed_data['status']['conditions'][0]['status']}"
      # puts "Type : #{parsed_data['status']['conditions'][0]['type']}"
      reason = parsed_data['status']['conditions'][0]['reason']
      level = reason == 'ProvisionCallFailed' ? 'error' : 'info'
      update_message(level, message)
    end
    set_final_state(reason)
    order.finalize_order
  end

  def set_final_state(reason)
    case reason
    when "ProvisionCallFailed"
      mark_failed
    when "ProvisionedSuccessfully"
      mark_finished
    else
      mark_finished
    end
  end

  def mark_failed
    self.completed_at = DateTime.now
    self.state = 'Failed'
    save!
  end

  def mark_finished
    self.completed_at = DateTime.now
    self.state = 'Completed'
    save!
  end
end
