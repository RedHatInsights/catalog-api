FactoryBot.define do
  factory :access_control_entry, :traits => [:has_tenant] do
    group_uuid { "123-456" }
    aceable_id { "6756" }
    aceable_type { "Portfolio" }

    trait :has_update_permission do
      access_control_permissions { [create(:access_control_permission, :has_update_permission)] }
    end

    trait :has_order_permission do
      access_control_permissions { [create(:access_control_permission, :has_order_permission)] }
    end

    trait :has_read_permission do
      access_control_permissions { [create(:access_control_permission, :has_read_permission)] }
    end

    trait :has_delete_permission do
      access_control_permissions { [create(:access_control_permission, :has_delete_permission)] }
    end

    trait :has_no_permission do
      access_control_permissions { [] }
    end

    trait :has_read_and_update_permission do
      access_control_permissions do
        [
          create(:access_control_permission, :has_read_permission),
          create(:access_control_permission, :has_update_permission),
        ]
      end
    end
  end
end
