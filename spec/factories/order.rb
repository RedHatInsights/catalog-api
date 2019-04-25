FactoryBot.define do
  factory :order do
    owner { UserHeaderSpecHelper::DEFAULT_USER['identity']['user']['username'] }
  end
end
