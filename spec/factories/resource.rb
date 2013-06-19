require 'cosmos/resource'

FactoryGirl.define do
  factory 'cosmos/resource' do
    server_entity
    create_method 'cosmos::set_resource'

    factory :resource do
      sequence(:id)   {  |n| "type-name#{n}" }
      quantity 50
      association :entity, :factory => :asteroid
    end
  end
end
