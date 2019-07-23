class CreateIcons < ActiveRecord::Migration[5.2]
  def up
    create_table :icons do |t|
      t.string :data
      t.string :source_ref
      t.string :source_id
      t.bigint :portfolio_item_id
      t.bigint :tenant_id
      t.index :tenant_id

      t.timestamps
    end

    puts <<~EOMESSAGE
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      After this migration, one needs to run
      `rake db:migrate:icons EMAIL=my_real_email@redhat.com`
      to actually move all of the icon references to the new table.

      Until this is done, the icon endpoints will be broken since the
      references aren't correct.
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    EOMESSAGE
  end

  def down
    drop_table :icons
    add_column :portfolio_items, :service_offering_icon_ref, :string
  end

  # Only gets called from `rake icons:migrate`, which needs to be run after this migration to move all of the
  # icons from a reference on PortfolioItem to the new Icon model
  def finalize_migration
    remove_column :portfolio_items, :service_offering_icon_ref, :string
  end
end
