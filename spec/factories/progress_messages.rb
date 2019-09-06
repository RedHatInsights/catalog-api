FactoryBot.define do
  factory :progress_message, :traits => [:has_tenant] do
    sequence(:message) { |n| "Message_#{n}" }
  end
end
