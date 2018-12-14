class CreateWebhook < ActiveRecord::Migration[5.1]
  def change
    create_table :webhooks do |t|
      t.bigint :tenant_id
      t.string :name
      t.string :url
      t.boolean :verify_ssl
      t.string :secret
      t.string :authentication
      t.string :userid
      t.string :password
      t.string :token

      t.timestamps
    end
  end
end
