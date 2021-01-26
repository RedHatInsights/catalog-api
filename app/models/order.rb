class Order < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Api::V1x0::Catalog::DiscardRestore

  FINISHED_STATES = ["Completed", "Failed", "Canceled"].freeze

  destroy_dependencies :order_items
  destroy_dependencies :progress_messages
  acts_as_tenant(:tenant)
  attribute :state, :string, :default => 'Created'
  validates_inclusion_of :state,
                         :in      => ["Approval Pending", "Canceled", "Completed", "Created", "Failed", "Ordered"].freeze,
                         :message => "state %{value} is not included in the list"

  default_scope { kept.order(:created_at => :desc) }

  has_many :order_items, -> { order(:process_sequence) }, :dependent => :destroy, :inverse_of => :order
  has_many :progress_messages, :as => :messageable, :dependent => :destroy, :inverse_of => :messageable

  before_create :set_defaults

  def set_defaults
    self.state = "Created"
  end

  def finished?
    FINISHED_STATES.include?(state)
  end

  def update_message(level, message)
    progress_messages << ProgressMessage.new(:level => level, :message => message, :tenant_id => tenant_id)
    touch
  end

  def mark_approval_pending(msg = nil)
    return if state == "Approval Pending"

    mark_item(msg, :state => "Approval Pending")
  end

  def mark_ordered(msg = nil)
    return if state == "Ordered"

    mark_item(msg, :order_request_sent_at => Time.now.utc, :state => "Ordered")
  end

  def mark_failed(msg = nil)
    return if state == "Failed"

    mark_item(msg, :completed_at => Time.now.utc, :state => "Failed", :level => "error")
  end

  def mark_completed(msg = nil)
    return if state == "Completed"

    mark_item(msg, :completed_at => Time.now.utc, :state => "Completed")
  end

  def mark_canceled(msg = nil)
    return if state == "Canceled"

    mark_item(msg, :completed_at => Time.now.utc, :state => "Canceled")
  end

  private

  def mark_item(msg, level: "info", **opts)
    update!(**opts)
    update_message(level, msg) if msg
    Rails.logger.send(level, "Updated Order: #{id} with '#{opts[:state]}' state".tap { |log| log << " message: #{msg}" }) if msg
  end
end
