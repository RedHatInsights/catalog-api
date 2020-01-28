class NormalizeAceTable < ActiveRecord::Migration[5.2]
  def up
    create_table(:permissions, &:timestamps)

    execute <<-SQL
      CREATE TYPE permissions_name AS ENUM ('read', 'delete', 'order', 'update');
    SQL
    add_column :permissions, :name, :permissions_name
    add_index :permissions, :name

    %w[read delete order update].each do |perm|
      Permission.create!(:name => perm)
    end

    create_table :access_control_permissions do |t|
      t.bigint :tenant_id
      t.bigint :access_control_entry_id
      t.bigint :permission_id

      t.timestamps

      t.index [:tenant_id, :access_control_entry_id, :permission_id], :name => "index_tenant_ace_permissions_on_ace_id_and_permission_id"
    end

    ###### -------Database Operations before table modification--------- ######

    # Lookup all distinct group, aceable entries
    ace_distinct = AccessControlEntry.distinct.pluck(:group_uuid, :aceable_type, :aceable_id)
    ace_distinct.each do |ace|
      # pull a group of all known group_uuid, aceable entries to grab the accumulated permissions
      aces = AccessControlEntry.where(:group_uuid => ace[0], :aceable_type => ace[1], :aceable_id => ace[2])
      perms = aces.map(&:permission)
      # Set the current record that we are going to deem the savable record
      current_ace = aces.first
      # Loop through the permissions and apply them to the current distinct ace record
      perms.each do |perm|
        permission = Permission.find_by(:name => perm)
        current_ace.access_control_permissions.build(:permission_id => permission.id, :tenant_id => current_ace.tenant_id)
      end
      # When finished with this ACE record, set the soon to be deleted permission record to 'distinct_group'
      current_ace.permission = 'distinct_group'
      current_ace.save!
    end

    # Destroy all ACE records that do not have a permission of 'distinct_group'
    AccessControlEntry.where.not(:permission => 'distinct_group').delete_all

    ###### ------------------------------------------------------------- ######

    remove_column :access_control_entries, :permission
    add_index(:access_control_entries, [:group_uuid, :aceable_type], :name => "index_on_group_uuid_aceable_type")
  end

  def down
    add_column :access_control_entries, :permission, :string
    add_index(:access_control_entries, [:group_uuid, :aceable_type, :permission], :name => "index_on_group_uuid_aceable_type_permission")

    ###### -------Database Operations before table modification--------- ######

    # Lookup all Access Control Entries
    AccessControlEntry.all.each do |entry|
      # Grab all current permissions for this group_uuid and aceable entity
      all_permissions = entry.permissions.map(&:name)
      # Apply each permission, starting with the current record, then create an identical record
      #  for the rest of the permissions
      all_permissions.each do |perm|
        if entry.permission.nil?
          entry.permission = perm
          entry.save!
        else
          AccessControlEntry.create!(:group_uuid => entry.group_uuid, :permission => perm, :aceable_type => entry.aceable_type, :aceable_id => entry.aceable_id)
        end
      end
    end

    ###### ------------------------------------------------------------- ######

    drop_table :permissions
    remove_index :access_control_entries, :name => :index_on_group_uuid_aceable_type
    execute <<-SQL
      DROP TYPE permissions_name;
    SQL
    drop_table :access_control_permissions
  end
end
