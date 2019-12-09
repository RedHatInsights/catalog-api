class CreateAccessControlEntry < ActiveRecord::Migration[5.2]
  def change
    create_table :access_control_entries do |t|
      t.string :group_uuid
      t.bigint :tenant_id
      t.string :permission
      t.references :aceable, :name => :access_control_entries, :polymorphic => true, :index => true

      t.timestamps
    end
  end
end
