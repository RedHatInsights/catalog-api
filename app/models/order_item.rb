class OrderItem < ApplicationRecord
  include OwnerField
  include Discard::Model
  acts_as_tenant(:tenant)

  before_discard :discard_progress_messages
  before_undiscard :restore_progress_messages

  default_scope -> { kept }

  validates_presence_of :count
  validates_presence_of :service_parameters
  validates_presence_of :order_id
  validates_presence_of :service_plan_ref
  validates_presence_of :portfolio_item_id

  belongs_to :order
  belongs_to :portfolio_item
  has_many :progress_messages, :dependent => :destroy
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

  private

  CHILD_DISCARD_TIME_LIMIT = 30

  def discard_progress_messages
    if progress_messages.map(&:discard).any? { |result| result == false }
      progress_messages.kept.each do |item|
        Rails.logger.error("OrderItem ID #{item.id} failed to be discarded")
      end

      err = "Failed to discard items from Order id: #{id} - not discarding order"
      Rails.logger.error(err)
      raise Discard::DiscardError, err
    end
  end

  def restore_progress_messages
    if progress_messages_to_restore.map(&:undiscard).any? { |result| result == false }
      progress_messages_to_restore.select(&:discarded?).each do |message|
        Rails.logger.error("ProgressMessage ID #{message.id} failed to be restored")
      end

      err = "Failed to restore progress messages from Order Item id: #{id} - not restoring order item"
      Rails.logger.error(err)
      raise Discard::DiscardError, err
    end
  end

  def progress_messages_to_restore
    progress_messages
      .with_discarded
      .discarded
      .select { |message| (message.discarded_at.to_i - discarded_at.to_i).abs < CHILD_DISCARD_TIME_LIMIT }
  end
end
