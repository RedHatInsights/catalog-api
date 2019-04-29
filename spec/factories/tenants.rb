FactoryBot.define do
  factory :tenant do
    external_tenant { UserHeaderSpecHelper::DEFAULT_USER['identity']['account_number'] }
  end
end
