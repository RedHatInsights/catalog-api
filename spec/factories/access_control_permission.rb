FactoryBot.define do
  factory :access_control_permission, :traits => [:has_tenant]

  trait :has_read_permission do
    permission
  end

  trait :has_update_permission do
    permission { Permission.create!(:name => 'update') }
  end

  trait :has_delete_permission do
    permission { Permission.create!(:name => 'delete') }
  end
end
