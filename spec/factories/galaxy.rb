require 'cosmos/entities/galaxy'

FactoryGirl.define do
  factory 'cosmos/entities/galaxy' do
    server_entity
    create_method 'cosmos::create_entity'

    factory :galaxy do
      sequence(:id)   {  |n| "galaxy#{n}" }
      sequence(:name) {  |n| "galaxy#{n}" }
      association :location, :strategy => :build
    end
  end
end
