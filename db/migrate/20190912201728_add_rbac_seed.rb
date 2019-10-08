class AddRbacSeed < ActiveRecord::Migration[5.2]
  def change
    create_table :rbac_seeds do |t|
      t.string :external_tenant
      t.timestamps
    end
    add_index :rbac_seeds, :external_tenant
  end
end
