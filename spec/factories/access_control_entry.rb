FactoryBot.define do
  factory :access_control_entry, :traits => [:has_tenant] do
    group_uuid { "123-456" }
    aceable_id { "6756" }
    permission { "read" }
    aceable_type { "Portfolio" }
  end
end
