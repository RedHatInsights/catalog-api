# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_07_09_201525) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_control_entries", force: :cascade do |t|
    t.string "group_uuid"
    t.bigint "tenant_id"
    t.string "aceable_type"
    t.bigint "aceable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aceable_type", "aceable_id"], name: "index_access_control_entries_on_aceable_type_and_aceable_id"
    t.index ["group_uuid", "aceable_type"], name: "index_on_group_uuid_aceable_type"
  end

  create_table "access_control_permissions", force: :cascade do |t|
    t.bigint "tenant_id"
    t.bigint "access_control_entry_id"
    t.bigint "permission_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "access_control_entry_id", "permission_id"], name: "index_tenant_ace_permissions_on_ace_id_and_permission_id"
  end

  create_table "ancillary_metadata", force: :cascade do |t|
    t.string "resource_type"
    t.bigint "resource_id"
    t.jsonb "statistics", default: "{}"
    t.bigint "tenant_id"
    t.datetime "updated_at", null: false
    t.index ["resource_type", "resource_id"], name: "index_ancillary_metadata_on_resource_type_and_resource_id"
  end

  create_table "approval_requests", force: :cascade do |t|
    t.string "approval_request_ref"
    t.integer "order_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reason"
    t.integer "state", default: 0
    t.bigint "tenant_id"
    t.datetime "request_completed_at"
    t.index ["tenant_id"], name: "index_approval_requests_on_tenant_id"
  end

  create_table "icons", force: :cascade do |t|
    t.string "source_ref"
    t.string "source_id"
    t.bigint "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.bigint "image_id"
    t.string "restore_to_type"
    t.bigint "restore_to_id"
    t.index ["discarded_at"], name: "index_icons_on_discarded_at"
    t.index ["restore_to_type", "restore_to_id"], name: "index_icons_on_restore_to_type_and_restore_to_id"
    t.index ["tenant_id"], name: "index_icons_on_tenant_id"
  end

  create_table "images", force: :cascade do |t|
    t.binary "content"
    t.string "extension"
    t.string "hashcode"
    t.bigint "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_images_on_tenant_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "count"
    t.bigint "order_id"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "order_request_sent_at"
    t.datetime "completed_at"
    t.datetime "updated_at", null: false
    t.string "topology_task_ref"
    t.bigint "tenant_id"
    t.string "service_plan_ref"
    t.bigint "portfolio_item_id"
    t.jsonb "service_parameters"
    t.jsonb "provider_control_parameters"
    t.jsonb "context"
    t.string "owner"
    t.string "external_url"
    t.string "insights_request_id"
    t.datetime "discarded_at"
    t.jsonb "service_parameters_raw"
    t.string "service_instance_ref"
    t.index ["discarded_at"], name: "index_order_items_on_discarded_at"
    t.index ["tenant_id"], name: "index_order_items_on_tenant_id"
  end

  create_table "order_process_tags", id: :serial, force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "order_process_id", null: false
    t.datetime "last_seen_at"
    t.index ["last_seen_at"], name: "index_order_process_tags_on_last_seen_at"
    t.index ["order_process_id", "tag_id"], name: "uniq_index_on_order_process_id_tag_id", unique: true
    t.index ["order_process_id"], name: "index_cluster_tags_on_order_process_id"
    t.index ["tag_id"], name: "index_order_process_tags_on_tag_id"
  end

  create_table "order_processes", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.bigint "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "before_portfolio_item_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "user_id"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "order_request_sent_at"
    t.datetime "completed_at"
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.string "owner"
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_orders_on_discarded_at"
    t.index ["tenant_id"], name: "index_orders_on_tenant_id"
  end

# Could not dump table "permissions" because of following StandardError
#   Unknown type 'permissions_name' for column 'name'

  create_table "portfolio_item_tags", id: :serial, force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "portfolio_item_id", null: false
    t.datetime "last_seen_at"
    t.index ["last_seen_at"], name: "index_portfolio_item_tags_on_last_seen_at"
    t.index ["portfolio_item_id", "tag_id"], name: "uniq_index_on_portfolio_item_id_tag_id", unique: true
    t.index ["portfolio_item_id"], name: "index_cluster_tags_on_portfolio_item_id"
    t.index ["tag_id"], name: "index_portfolio_item_tags_on_tag_id"
  end

  create_table "portfolio_items", force: :cascade do |t|
    t.boolean "favorite"
    t.string "description"
    t.boolean "orphan"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.string "service_offering_ref"
    t.bigint "portfolio_id"
    t.string "service_offering_source_ref"
    t.string "name"
    t.string "long_description"
    t.string "distributor"
    t.string "documentation_url"
    t.string "support_url"
    t.datetime "discarded_at"
    t.string "owner"
    t.string "service_offering_icon_ref"
    t.string "service_offering_type"
    t.bigint "icon_id"
    t.index ["discarded_at"], name: "index_portfolio_items_on_discarded_at"
    t.index ["tenant_id"], name: "index_portfolio_items_on_tenant_id"
  end

  create_table "portfolio_tags", id: :serial, force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "portfolio_id", null: false
    t.datetime "last_seen_at"
    t.index ["last_seen_at"], name: "index_portfolio_tags_on_last_seen_at"
    t.index ["portfolio_id", "tag_id"], name: "uniq_index_on_portfolio_id_tag_id", unique: true
    t.index ["portfolio_id"], name: "index_cluster_tags_on_portfolio_id"
    t.index ["tag_id"], name: "index_portfolio_tags_on_tag_id"
  end

  create_table "portfolios", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "enabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.datetime "discarded_at"
    t.string "owner"
    t.bigint "icon_id"
    t.index ["discarded_at"], name: "index_portfolios_on_discarded_at"
    t.index ["tenant_id"], name: "index_portfolios_on_tenant_id"
  end

  create_table "progress_messages", force: :cascade do |t|
    t.datetime "received_at"
    t.string "level"
    t.string "message"
    t.string "order_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_progress_messages_on_discarded_at"
    t.index ["tenant_id"], name: "index_progress_messages_on_tenant_id"
  end

  create_table "rbac_seeds", force: :cascade do |t|
    t.string "external_tenant"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_tenant"], name: "index_rbac_seeds_on_external_tenant"
  end

  create_table "service_plans", force: :cascade do |t|
    t.jsonb "base"
    t.jsonb "modified"
    t.bigint "portfolio_item_id"
    t.bigint "tenant_id"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "description"
    t.index ["discarded_at"], name: "index_service_plans_on_discarded_at"
    t.index ["tenant_id"], name: "index_service_plans_on_tenant_id"
  end

  create_table "tag_links", force: :cascade do |t|
    t.bigint "tenant_id"
    t.bigint "order_process_id"
    t.string "app_name"
    t.string "object_type"
    t.string "tag_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_name", "object_type", "tag_name", "tenant_id"], name: "index_tag_links_on_app_type_tag", unique: true
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "name", null: false
    t.string "value", default: "", null: false
    t.string "namespace", default: "", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.index ["tenant_id", "namespace", "name", "value"], name: "index_tags_on_tenant_id_and_namespace_and_name_and_value", unique: true
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_tenant"
    t.string "name"
    t.string "description"
    t.jsonb "settings", default: {}
    t.index ["external_tenant"], name: "index_tenants_on_external_tenant"
  end

  add_foreign_key "order_process_tags", "order_processes", on_delete: :cascade
  add_foreign_key "order_process_tags", "tags", on_delete: :cascade
  add_foreign_key "portfolio_item_tags", "portfolio_items", on_delete: :cascade
  add_foreign_key "portfolio_item_tags", "tags", on_delete: :cascade
  add_foreign_key "portfolio_tags", "portfolios", on_delete: :cascade
  add_foreign_key "portfolio_tags", "tags", on_delete: :cascade
  add_foreign_key "tags", "tenants", on_delete: :cascade
end
