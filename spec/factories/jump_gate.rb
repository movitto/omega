require 'cosmos/entities/jump_gate'

FactoryGirl.define do
  factory 'cosmos/entities/jump_gate' do
    server_entity
    create_method 'cosmos::create_entity'

    factory :jump_gate do
      sequence(:id)   {  |n| "jg#{n}" }
      sequence(:name) {  |n| "jg#{n}" }

      association :endpoint, factory: :solar_system

      association :location, :strategy => :build
      solar_system
    end
  end
end
