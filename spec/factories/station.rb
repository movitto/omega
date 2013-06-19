require 'manufactured/station'

FactoryGirl.define do
  factory 'manufactured/station' do
    server_entity
    create_method 'manufactured::create_entity'

    factory :station do
      sequence(:id, 10000) { |n| "station#{n}" }

      factory :valid_station do
        type :manufacturing
        user_id { create(:user).id }
        solar_system
      end
    end
  end
end
