require 'cosmos/entities/star'

FactoryGirl.define do
  factory 'cosmos/entities/star' do
    server_entity
    create_method 'cosmos::create_entity'

    factory :star do
      sequence(:id)   {  |n| "star#{n}" }
      sequence(:name) {  |n| "star#{n}" }
      association :location, factory: :star1_location, :strategy => :build
    end
  end
end
