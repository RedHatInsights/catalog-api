FactoryBot.define do
  factory :tenant do
    external_tenant { default_account_number }
  end
end
