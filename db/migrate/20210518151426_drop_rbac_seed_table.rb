class DropRbacSeedTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :rbac_seeds
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
