class AddPreIdToOrderProcesses < ActiveRecord::Migration[5.2]
  def change
    add_column :order_processes, :pre_id, :integer
  end
end
