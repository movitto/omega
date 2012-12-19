require 'cosmos/registry'
require 'cosmos/solar_system'

FactoryGirl.define do
  factory :server_solar_system, class: Cosmos::SolarSystem do
    ignore do
      galaxy :gal1
    end

    after(:build) { |s,e|
      FactoryGirl.build(e.galaxy)
      g = Cosmos::Registry.instance.find_entity(:name => e.galaxy.to_s)
      g.add_child(s) unless g.has_child?(s.name)
    }
  end

  factory :sys1, parent: :server_solar_system do
    name     'sys1'
    association :location, factory: :sys1_location, :strategy => :build
  end

  factory :sys2, parent: :server_solar_system do
    name     'sys2'
    association :location, factory: :sys2_location, :strategy => :build
  end

  factory :sys3, parent: :server_solar_system do
    name     'sys3'
    association :location, factory: :sys3_location, :strategy => :build
  end
end
