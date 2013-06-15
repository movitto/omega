require 'cosmos/entities/solar_system'

FactoryGirl.define do
  factory 'cosmos/entities/solar_system' do
    server_entity
    create_method 'cosmos::create_entity'

    factory :solar_system do
      sequence(:id)   {  |n| "system#{n}" }
      sequence(:name) {  |n| "system#{n}" }
      association :location, :strategy => :build
      galaxy
    end
  end
end
