require 'cosmos/entities/asteroid'

FactoryGirl.define do
  factory 'cosmos/entities/asteroid' do
    server_entity
    create_method 'cosmos::create_entity'

    factory :asteroid do
      sequence(:id)   {  |n| "asteroid#{n}" }
      sequence(:name) {  |n| "asteroid#{n}" }
      association :location, :strategy => :build
      solar_system
    end
  end
end
