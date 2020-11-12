class AddMessageableToProgressMessages < ActiveRecord::Migration[5.2]
  def up
    add_reference :progress_messages, :messageable, :polymorphic => true

    ProgressMessage.all.each do |message|
      message.update(
        :messageable_type => "OrderItem",
        :messageable_id   => message.order_item_id
      )
    end

    # Leave for future to remove
    # remove_column :progress_messages, :order_item_id, :string
  end

  def down
    # add_column :progress_messages, :order_item_id, :string

    ProgressMessage.all.each do |message|
      case message.messageable_type
      when "OrderItem"
        message.update!(:order_item_id => message.messageable_id)
      when "Order"
        message.delete
      end
    end

    remove_reference :progress_messages, :messageable, :polymorphic => true
  end
end
