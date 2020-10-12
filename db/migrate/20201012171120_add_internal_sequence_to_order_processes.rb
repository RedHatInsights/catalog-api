class AddInternalSequenceToOrderProcesses < ActiveRecord::Migration[5.2]
  def change
    add_column :order_processes, :internal_sequence, :decimal

    add_index  :order_processes, [:internal_sequence, :tenant_id], :unique => true
  end
end
