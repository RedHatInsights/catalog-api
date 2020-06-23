FactoryBot.define do
  factory :order_process, :traits => [:has_tenant] do
    name { 'order_process_name' }
  end
end
