FactoryBot.define do
  factory :tenant do
    external_tenant { default_account_number }
    settings do
      {
        :icon             => "<svg rel='stylesheet'>image</svg>",
        :default_workflow => "1"
      }
    end
  end
end
