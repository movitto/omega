require 'manufactured/ship'

FactoryGirl.define do
  factory 'manufactured/ship' do
    server_entity
    create_method 'manufactured::create_entity'

    factory :ship do
      sequence(:id, 10000) { |n| "ship#{n}" }

      factory :valid_ship do
        type :frigate
        user_id { create(:user).id }
        solar_system
      end
    end
  end
end
