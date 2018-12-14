class RenameExternalRef < ActiveRecord::Migration[5.1]
  def change
    rename_column :order_items, :external_ref, :topology_task_ref
  end
end
