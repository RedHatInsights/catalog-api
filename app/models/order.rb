class Order < ApplicationRecord
  include OwnerField
  include Discard::Model
  acts_as_tenant(:tenant)

  default_scope { kept.order(:created_at => :desc) }

  has_many :order_items, :dependent => :destroy

  before_create :set_defaults

  before_discard :discard_order_items
  before_undiscard :restore_order_items

  def set_defaults
    self.state = "Created"
  end

  private

  CHILD_DISCARD_TIME_LIMIT = 30

  def discard_order_items
    if order_items.map(&:discard).any? { |result| result == false }
      order_items.kept.each do |item|
        Rails.logger.error("OrderItem ID #{item.id} failed to be discarded")
      end

      err = "Failed to discard items from Order id: #{id} - not discarding order"
      Rails.logger.error(err)
      raise Discard::DiscardError, err
    end
  end

  def restore_order_items
    if order_items_to_restore.map(&:undiscard).any? { |result| result == false }
      order_items_to_restore.select(&:discarded?).each do |item|
        Rails.logger.error("OrderItem ID #{item.id} failed to be restored")
      end

      err = "Failed to restore items from Order id: #{id} - not restoring order"
      Rails.logger.error(err)
      raise Discard::DiscardError, err
    end
  end

  def order_items_to_restore
    order_items
      .with_discarded
      .discarded
      .select { |item| (item.discarded_at.to_i - discarded_at.to_i).abs < CHILD_DISCARD_TIME_LIMIT }
  end
end
