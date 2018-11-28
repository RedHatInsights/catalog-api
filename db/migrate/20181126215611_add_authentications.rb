class AddAuthentications < ActiveRecord::Migration[5.1]
  def change
    create_table :authentications, :id => :bigserial do |t|
      t.references "resource", :polymorphic => true, :index => true
      t.string     :name
      t.string     :authtype
      t.string     :status
      t.string     :status_details
      t.bigint     :tenant_id

      t.timestamps
    end

    create_table :encryptions, :id => :bigserial do |t|
      t.references "authentication", :index => true
      t.string :password
      t.bigint :tenant_id

      t.timestamps
    end
  end
end
