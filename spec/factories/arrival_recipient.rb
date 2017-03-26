FactoryGirl.define do
  factory :arrival_recipient do
    email_address 'pomrecipient@example.com'
    notification_method 'email'
  end
end
