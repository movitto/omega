require 'cosmos/jump_gate'

FactoryGirl.define do
  factory :jump_gate, class: Cosmos::JumpGate do
  end

  factory :jump_gate1, parent: :jump_gate do
    association :solar_system, factory: :sys1, strategy: :build
    association :endpoint,     factory: :sys2, strategy: :build

    association :location, factory: :jump_gate1_location, :strategy => :build
  end
end
