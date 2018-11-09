class CreateWebhook < ActiveRecord::Migration[5.1]
  def change
    create_table :webhooks do |t|
      t.bigint :tenant_id
      t.string :name
      t.jsonb  :parameters

      t.timestamps
    end
  end
end
