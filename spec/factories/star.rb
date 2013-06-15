require 'cosmos/entities/star'

FactoryGirl.define do
  factory 'cosmos/entities/star' do
    server_entity
    create_method 'cosmos::create_entity'

    factory :star do
      sequence(:id)   {  |n| "star#{n}" }
      sequence(:name) {  |n| "star#{n}" }
      size      450
      color    'FFFF00'

      association :location, :strategy => :build
      solar_system
    end
  end
end
