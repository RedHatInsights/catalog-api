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

ActiveRecord::Schema.define(version: 20181022121618) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "catalog_items", id: false, force: :cascade do |t|
    t.string "provider_id"
    t.bigint "portfolio_item_id"
    t.string "catalog_id"
    t.string "name"
    t.string "description"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "catalog_plans", id: false, force: :cascade do |t|
    t.string "plan_id"
    t.string "name"
    t.string "description"
    t.string "catalog_id"
    t.string "provider_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "count"
    t.string "parameters"
    t.string "plan_id"
    t.string "catalog_id"
    t.string "provider_id"
    t.string "order_id"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "ordered_at"
    t.datetime "completed_at"
    t.datetime "updated_at", null: false
    t.string "external_ref"
    t.bigint "tenant_id"
    t.index ["tenant_id"], name: "index_order_items_on_tenant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "user_id"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "ordered_at"
    t.datetime "completed_at"
    t.string "order_items"
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.index ["tenant_id"], name: "index_orders_on_tenant_id"
  end

  create_table "parameter_values", id: false, force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.string "type"
    t.string "format"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plan_parameters", id: false, force: :cascade do |t|
    t.string "type"
    t.string "title"
    t.string "name"
    t.string "description"
    t.string "default"
    t.string "pattern"
    t.string "example"
    t.boolean "required"
    t.string "format"
    t.string "enum"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "portfolio_items", force: :cascade do |t|
    t.boolean "favorite"
    t.string "name"
    t.string "description"
    t.boolean "orphan"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.string "service_offering_ref"
    t.index ["tenant_id"], name: "index_portfolio_items_on_tenant_id"
  end

  create_table "portfolio_items_portfolios", id: false, force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.bigint "portfolio_item_id", null: false
    t.index ["portfolio_id", "portfolio_item_id"], name: "index_items_on_portfolio_id_and_portfolio_item_id"
    t.index ["portfolio_item_id", "portfolio_id"], name: "index_items_on_portfolio_item_id_and_portfolio_id"
  end

  create_table "portfolios", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "enabled"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
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
    t.index ["tenant_id"], name: "index_progress_messages_on_tenant_id"
  end

  create_table "providers", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "url"
    t.string "user"
    t.string "password"
    t.string "token"
    t.boolean "verify_ssl"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "ref_id"
    t.index ["ref_id"], name: "index_tenants_on_ref_id"
  end

end
