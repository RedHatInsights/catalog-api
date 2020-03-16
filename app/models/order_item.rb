class OrderItem < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Catalog::DiscardRestore
  destroy_dependencies :progress_messages

  acts_as_tenant(:tenant)

  default_scope -> { kept }

  validates_presence_of :count
  validates_presence_of :order_id
  validates_presence_of :portfolio_item_id

  belongs_to :order
  belongs_to :portfolio_item
  has_many :progress_messages, :dependent => :destroy
  has_many :approval_requests, :dependent => :destroy

  before_create :set_defaults
  before_save :sanitize_parameters, :if => :will_save_change_to_service_parameters?

  def set_defaults
    self.state = "Created"

    if Insights::API::Common::Request.current.present?
      self.context = Insights::API::Common::Request.current.to_h
      self.insights_request_id = Insights::API::Common::Request.current.request_id
    end
  end

  def update_message(level, message)
    progress_messages << ProgressMessage.new(:level => level, :message => message, :tenant_id => self.tenant_id)
    touch
  end

  def mark_completed(msg = nil, **opts)
    mark_item(msg, :completed_at => DateTime.now, :state => "Completed", **opts)
  end

  def mark_failed(msg = nil, **opts)
    mark_item(msg, :completed_at => DateTime.now, :state => "Failed", :level => "error", **opts)
  end

  def mark_ordered(msg = nil, **opts)
    mark_item(msg, :order_request_sent_at => DateTime.now, :state => "Ordered",  **opts)
  end

  private

  def sanitize_parameters
    # Store the API accessible parameters with protected field values masked
    self.service_parameters_raw = self[:service_parameters]

    self[:service_parameters] = Catalog::OrderItemSanitizedParameters.new(:order_item => self).process.sanitized_parameters
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
    Rails.logger.send(level, "Updated OrderItem: #{id} with '#{opts[:state]}' state".tap { |log| log << " message: #{msg}" if msg })

    Catalog::OrderStateTransition.new(order).process
  end
end
