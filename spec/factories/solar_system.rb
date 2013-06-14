require 'cosmos/entities/solar_system'

FactoryGirl.define do
  factory 'cosmos/entities/solar_system' do
    server_entity
    create_method 'cosmos::create_entity'

    factory :system do
      sequence(:id)   {  |n| "galaxy#{n}" }
      sequence(:name) {  |n| "galaxy#{n}" }
      association :location, factory: :sys1_location
    end
  end
end
