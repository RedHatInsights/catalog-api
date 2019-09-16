FactoryBot.define do
  trait :has_tenant do
    tenant { Tenant.first_or_create!(:external_tenant => default_account_number) }
  end

  trait :has_owner do
    owner { default_username }
  end
end
