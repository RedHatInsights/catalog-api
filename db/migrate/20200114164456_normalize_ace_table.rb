class NormalizeAceTable < ActiveRecord::Migration[5.2]
  def up
    create_table :permissions do |t|
      t.integer :name

      t.timestamps
    end

    create_join_table :access_control_entries, :permissions do |t|
      t.index [:access_control_entry_id, :permission_id], :name => "index_ace_permissions_on_ace_id_and_permission_id"
    end

    (0..3).each do |permission|
      Permission.create!(:name => permission)
    end

    AccessControlEntry.all.each do |entry|
      perm = entry.send(:permission)
      permission = Permission.find_by(:name => perm)
      entry.permissions << permission
    end

    remove_column :access_control_entries, :permission
    add_index(:access_control_entries, [:group_uuid, :aceable_type], :name => "index_on_group_uuid_aceable_type")
  end

  def down
    add_column :access_control_entries, :permission, :string
    add_index(:access_control_entries, [:group_uuid, :aceable_type, :permission], :name => "index_on_group_uuid_aceable_type_permission")
    drop_table :permissions
    drop_join_table :access_control_entries, :permissions
  end
end
