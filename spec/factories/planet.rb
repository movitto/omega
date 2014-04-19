require 'cosmos/entities/planet'

FactoryGirl.define do
  factory 'cosmos/entities/planet' do
    server_entity
    create_method 'cosmos::create_entity'

    factory :planet do
      sequence(:id)   {  |n| "planet#{n}" }
      sequence(:name) {  |n| "planet#{n}" }
      size      55
      type       0

      association :location, :strategy => :build
      solar_system
    end
  end
end
