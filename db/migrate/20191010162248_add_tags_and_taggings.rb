class AddTagsAndTaggings < ActiveRecord::Migration[5.2]
  def change
    create_table "tags", :id => :serial, :force => :cascade do |t|
      t.references :tenant, :type => :bigint, :index => false, :null => false, :foreign_key => {:on_delete => :cascade}

      t.string "name", :null => false
      t.string "value", :null => false, :default => ''
      t.string "namespace", :default => '', :null => false
      t.text "description"
      t.datetime "created_at", :null => false

      t.index ["tenant_id", "namespace", "name"], :unique => true
    end

    create_table "portfolio_tags", :id => :serial, :force => :cascade do |t|
      t.references :tag, :type => :bigint, :index => true, :null => false, :foreign_key => {:on_delete => :cascade}
      t.references :portfolio, :type => :bigint, :index => false, :null => false, :foreign_key => {:on_delete => :cascade}
      t.datetime :last_seen_at

      t.index ["portfolio_id"], :name => "index_cluster_tags_on_portfolio_id"
      t.index ["portfolio_id", "tag_id"], :name => "uniq_index_on_portfolio_id_tag_id", :unique => true
      t.index :last_seen_at
    end

    create_table "portfolio_item_tags", :id => :serial, :force => :cascade do |t|
      t.references :tag, :type => :bigint, :index => true, :null => false, :foreign_key => {:on_delete => :cascade}
      t.references :portfolio_item, :type => :bigint, :index => false, :null => false, :foreign_key => {:on_delete => :cascade}
      t.datetime :last_seen_at

      t.index ["portfolio_item_id"], :name => "index_cluster_tags_on_portfolio_item_id"
      t.index ["portfolio_item_id", "tag_id"], :name => "uniq_index_on_portfolio_item_id_tag_id", :unique => true
      t.index :last_seen_at
    end
  end
end
