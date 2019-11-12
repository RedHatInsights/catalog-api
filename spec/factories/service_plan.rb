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

    sequence(:modified) do |n|
      {
        "schema" => {
          :title       => "Factory Modified Schema #{n}",
          :description => "A Modified Schema #{n}"
        }
      }
    end

    portfolio_item
  end
end
