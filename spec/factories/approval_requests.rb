FactoryBot.define do
  factory :approval_request, :traits => [:has_tenant] do
    sequence(:approval_request_ref)
    state { :undecided }

    order_item
  end
end
