FactoryBot.define do
  factory :service_plan, :traits => [:has_tenant] do
    sequence(:base) do |n|
      {
        "schema" => {
          :title       => "Factory Schema #{n}",
          :description => "A Generated Schema #{n}"
        }
      }
    end

    modified { base }

    portfolio_item
  end
end
