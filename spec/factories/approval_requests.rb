FactoryBot.define do
  factory :approval_request do
    approval_request_ref { "MyString" }
    workflow_ref { "MyString" }
    state { :undecided }
    order_item_id { "" }
  end
end
