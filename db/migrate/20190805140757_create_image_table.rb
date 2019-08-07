class CreateImageTable < ActiveRecord::Migration[5.2]
  def up
    create_table :images do |t|
      t.binary(:content)
      t.string :extension
      t.bigint :tenant_id
      t.index :tenant_id

      t.timestamps
    end

    add_column :icons, :image_id, :bigint

    Icon.all.each do |icon|
      image = Image.create!(
        :content   => icon.data,
        :extension => "svg",
        :tenant_id => icon.tenant_id
      )

      icon.update(:image_id => image.id)
    end

    remove_column :icons, :data
  end

  def down
    drop_table :images
    add_column :icons, :data, :string
  end
end
