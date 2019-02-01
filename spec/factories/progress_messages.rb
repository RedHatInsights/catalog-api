FactoryBot.define do
  factory :progress_message do
    sequence(:message) { |n| "Message_#{n}" }
  end
end
