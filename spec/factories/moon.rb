require 'cosmos/entities/moon'

FactoryGirl.define do
  factory 'cosmos/entities/moon' do
    server_entity
    create_method 'cosmos::create_entity'

    factory :moon do
      sequence(:id)   {  |n| "moon#{n}" }
      sequence(:name) {  |n| "moon#{n}" }
      association :location, :strategy => :build
      planet
    end
  end
end
