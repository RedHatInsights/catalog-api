class AddOrderIdToProgressMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :progress_messages, :order_id, :string
  end
end
