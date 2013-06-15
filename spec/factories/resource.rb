require 'cosmos/resource'

FactoryGirl.define do
  factory 'cosmos/resource' do
    server_entity
    create_method 'cosmos::create_resource'

    factory :resource do
      sequence(:id)   {  |n| "type-name#{n}" }
      #association :entity, :strategy => :build
      quantity 50
    end
  end
end
