FactoryBot.define do
  factory :order_process, :traits => [:has_tenant] do
    sequence(:name) { |n| "order_process_name_#{n}" }
  end
end
