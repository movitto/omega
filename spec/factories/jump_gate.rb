require 'cosmos/jump_gate'

FactoryGirl.define do
  factory :server_jump_gate, class: Cosmos::JumpGate do
    ignore do
      system :sys1
    end

    after(:build) { |jg,e|
      FactoryGirl.build(e.system)
      s = Cosmos::Registry.instance.find_entity(:name => e.system.to_s)
      s.add_child(jg) #unless s.has_child?(jg)
    }
  end

  factory :jump_gate1, parent: :server_jump_gate do
    association :solar_system, factory: :sys1, strategy: :build
    association :endpoint,     factory: :sys2, strategy: :build

    association :location, factory: :jump_gate1_location, :strategy => :build
  end

  factory :jump_gate2, parent: :server_jump_gate do
    association :solar_system, factory: :sys1, strategy: :build
    association :endpoint,     factory: :sys3, strategy: :build

    association :location, factory: :jump_gate2_location, :strategy => :build
  end
end
