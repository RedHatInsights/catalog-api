class AddOrderProcess < ActiveRecord::Migration[5.2]
  def change
    create_table "order_process".pluralize.to_sym do |t|
      t.string :name, :null => false
      t.string :description
      t.bigint :tenant_id

      t.timestamps
    end

    create_table "order_process_tags", :id => :serial, :force => :cascade do |t|
      t.references :tag, :type => :bigint, :index => true, :null => false, :foreign_key => {:on_delete => :cascade}
      t.references :order_process, :type => :bigint, :index => false, :null => false, :foreign_key => {:on_delete => :cascade}
      t.datetime :last_seen_at

      t.index ["order_process_id"], :name => "index_cluster_tags_on_order_process_id"
      t.index ["order_process_id", "tag_id"], :name => "uniq_index_on_order_process_id_tag_id", :unique => true
      t.index :last_seen_at
    end
  end
end
