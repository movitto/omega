require 'manufactured/ship'

FactoryGirl.define do
  factory :ship, class: Manufactured::Ship do
  end

  factory :ship1, parent: :ship do
    id      'ship1'
    user_id 'user1'

    association :solar_system, factory: :solar_system1, :strategy => :build
    association :location, factory: :ship1_location, :strategy => :build
  end

  factory :ship2, parent: :ship do
    id      'ship2'
    user_id 'user1'

    association :solar_system, factory: :solar_system1, :strategy => :build
    association :location, factory: :ship2_location, :strategy => :build
  end

end
