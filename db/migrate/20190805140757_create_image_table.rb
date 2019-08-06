class CreateImageTable < ActiveRecord::Migration[5.2]
  def up
    create_table :images do |t|
      t.binary :content
      t.string :type
      t.bigint :tenant_id
      t.index :tenant_id

      t.timestamps
    end

    ### TODO: move all current icons to new table.

    remove_column :icons, :data
    add_column :icons, :image_id, :bigint
  end

  def down
    drop_table :images
    add_column :icons, :data, :string
  end
end
