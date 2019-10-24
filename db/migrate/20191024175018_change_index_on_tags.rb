class ChangeIndexOnTags < ActiveRecord::Migration[5.2]
  def change
    remove_index :tags, :column => ["tenant_id", "namespace", "name"]
    add_index :tags, ["tenant_id", "namespace", "name", "value"], :unique => true
  end
end
