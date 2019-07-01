class CreateIcons < ActiveRecord::Migration[5.2]
  def change
    create_table :icons do |t|
      t.string :data
      t.string :source_ref
      t.string :source_id
      t.bigint :portfolio_item_id
      t.bigint :tenant_id
      t.index :tenant_id

      t.timestamps
    end

    remove_column :portfolio_items, :service_offering_icon_ref, :string
  end
end
