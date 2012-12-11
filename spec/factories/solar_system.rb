require 'cosmos/solar_system'

FactoryGirl.define do
  factory :solar_system, class: Cosmos::SolarSystem do
  end

  factory :sys1, parent: :solar_system do
    name     'sys1'

    association :location, factory: :sys1_location, :strategy => :build
  end

  factory :sys2, parent: :solar_system do
    name     'sys2'

    association :location, factory: :sys2_location, :strategy => :build
  end

  factory :sys3, parent: :solar_system do
    name     'sys3'

    association :location, factory: :sys3_location, :strategy => :build
  end
end
