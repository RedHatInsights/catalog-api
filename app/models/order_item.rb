class OrderItem < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Api::V1x0::Catalog::DiscardRestore
  FINISHED_STATES = ["Completed", "Failed", "Canceled", "Denied"].freeze

  destroy_dependencies :progress_messages
  attribute :state, :string, :default => 'Created'
  validates_inclusion_of :state,
                         :in      => ["Approval Pending", "Approved", "Canceled", "Completed", "Created", "Denied", "Failed", "Ordered"].freeze,
                         :message => "state %{value} is not included in the list"

  acts_as_tenant(:tenant)

  default_scope -> { kept }

  validates_presence_of :count
  validates_presence_of :order_id
  validates_presence_of :portfolio_item_id

  belongs_to :order, :inverse_of => :order_items
  belongs_to :portfolio_item
  has_many :approval_requests, :dependent => :destroy
  has_many :progress_messages, :as => :messageable, :dependent => :destroy, :inverse_of => :messageable

  before_create :set_defaults
  before_save :sanitize_parameters, :if => :will_save_change_to_service_parameters?

  def set_defaults
    self.state = "Created"

    if Insights::API::Common::Request.current.present?
      self.context = Insights::API::Common::Request.current.to_h
      self.insights_request_id = Insights::API::Common::Request.current.request_id
    end
  end

  def can_order?
    state == (process_scope == 'product' ? 'Approved' : 'Created')
  end

  def update_message(level, message)
    progress_messages << ProgressMessage.new(:level => level, :message => message, :tenant_id => tenant_id)
    touch
  end

  def mark_completed(msg = nil, **opts)
    mark_item(msg, :completed_at => DateTime.now, :state => "Completed", **opts)
    Catalog::SubmitNextOrderItem.new(order_id).process
  end

  def mark_failed(msg = nil, **opts)
    mark_item(msg, :completed_at => DateTime.now, :state => "Failed", :level => "error", **opts)
    Catalog::SubmitNextOrderItem.new(order_id).process
  end

  def mark_ordered(msg = nil, **opts)
    mark_item(msg, :order_request_sent_at => DateTime.now, :state => "Ordered", **opts)
  end

  def clear_sensitive_service_parameters
    self[:service_parameters_raw] = nil
    save!
  end

  def service_parameters_raw
    self[:service_parameters_raw] || self[:service_parameters]
  end

  private

  def sanitize_parameters
    # Store the API accessible parameters with protected field values masked
    sanitized_parameters = Catalog::OrderItemSanitizedParameters.new(self).process.sanitized_parameters
    return if sanitized_parameters == service_parameters

    self.service_parameters_raw = self[:service_parameters]
    self[:service_parameters] = sanitized_parameters
  end

  def service_parameters_raw=(val)
    raise Catalog::InvalidParameter, "Error: Masked parameters being saved to service_parameters_raw" if parameters_contain_sanitized_values?(val)

    self[:service_parameters_raw] = val
  end

  def parameters_contain_sanitized_values?(val)
    val.to_s.include?("\"#{Catalog::OrderItemSanitizedParameters::MASKED_VALUE}\"")
  end

  def mark_item(msg, level: "info", **opts)
    update!(**opts)
    update_message(level, msg) if msg
    Rails.logger.send(level, "Updated OrderItem: #{id} with '#{opts[:state]}' state".tap { |log| log << " message: #{msg}" }) if msg

    order.reload
    Catalog::OrderStateTransition.new(order).process
  end
end
