require 'omega/server/event'

FactoryGirl.define do
  factory 'omega/server/event' do
    server_entity
    create_method 'missions::create_event'

    factory :event do
      sequence(:id)   {  |n| "event#{n}" }
    end
  end
end
