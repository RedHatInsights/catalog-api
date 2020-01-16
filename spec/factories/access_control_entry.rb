FactoryBot.define do
  factory :access_control_entry, :traits => [:has_tenant] do
    group_uuid { "123-456" }
    aceable_id { "6756" }
    aceable_type { "Portfolio" }

    trait :has_update_permission do
      permissions { [Permission.create!(:name => 'update')] }
    end

    trait :has_read_permission do
      permissions { [Permission.create!(:name => 'read')] }
    end

    trait :has_delete_permission do
      permissions { [Permission.create!(:name => 'delete')] }
    end

    trait :has_read_and_update_permission do
      permissions { [Permission.create!(:name => 'read'), Permission.create!(:name => 'update')] }
    end
  end
end
