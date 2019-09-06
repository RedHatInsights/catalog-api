FactoryBot.define do
  factory :approval_request, :traits => [:has_tenant] do
    approval_request_ref { "MyString" }
    workflow_ref { "MyString" }
    state { :undecided }

    order_item
  end
end
