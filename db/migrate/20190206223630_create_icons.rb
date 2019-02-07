class CreateIcons < ActiveRecord::Migration[5.2]
  def change
    create_table :icons do |t|
      t.string :source_ref
      t.string :data

      t.timestamps
    end

    add_column :portfolio_items, :service_offering_icon_id, :bigint

  end
end
