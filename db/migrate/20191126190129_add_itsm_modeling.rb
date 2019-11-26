class AddItsmModeling < ActiveRecord::Migration[5.2]
  def change
    create_table :order_templates do |t|
      t.string :description
      t.string :name
      t.jsonb :post_hash
      t.bigint :post_provision_id
      t.bigint :pre_provision_id
      t.jsonb :pre_hash
      t.references :prepostable, :polymorphic => true
      t.jsonb :provision_hash

      t.bigint :tenant_id

      t.datetime :discarded_at
      t.index :discarded_at
      t.timestamps
    end
  end
end
