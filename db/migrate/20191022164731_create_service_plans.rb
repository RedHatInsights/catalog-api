class CreateServicePlans < ActiveRecord::Migration[5.2]
  def change
    create_table :service_plans do |t|
      t.jsonb :base
      t.jsonb :modified

      t.bigint :portfolio_item_id
      t.bigint :tenant_id
      t.index :tenant_id
      t.datetime :discarded_at
      t.index :discarded_at

      t.timestamps
    end
  end
end
