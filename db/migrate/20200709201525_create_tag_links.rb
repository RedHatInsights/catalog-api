class CreateTagLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :tag_links do |t|
      t.bigint :tenant_id
      t.bigint :order_process_id
      t.string :app_name
      t.string :object_type
      t.string :tag_name

      t.timestamps
    end

    add_index :tag_links, [:app_name, :object_type, :tag_name, :tenant_id], :unique => true, :name => 'index_tag_links_on_app_type_tag'
  end
end
