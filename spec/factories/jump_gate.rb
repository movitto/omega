require 'cosmos/entities/jump_gate'

FactoryGirl.define do
  factory 'cosmos/server/jump_gate' do
    server_entity
    create_method 'cosmos::create_entity'

    factory :jump_gate do
      association :solar_system, factory: :sys1
      association :endpoint,     factory: :sys2
      association :location, factory: :jump_gate1_location
    end
  end
end
