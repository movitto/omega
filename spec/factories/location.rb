require 'motel/location'
require 'motel/movement_strategies/stopped'
require 'motel/movement_strategies/elliptical'
require 'motel/movement_strategies/follow'
require 'motel/movement_strategies/linear'

FactoryGirl.define do
  factory :location, class: Motel::Location do
    x  0
    y  0
    z  0
    parent_id nil
  end

  factory :unv_location, parent: :location do
    id 100
  end

  factory :gal1_location, parent: :location do
    id   200
    x    10
    y    10
    z    10

    parent_id 100
  end
  
  factory :sys1_location, parent: :location do
    id   300
    x    10
    y    10
    z    10

    parent_id 200
  end

  factory :sys2_location, parent: :location do
    id   301
    x    -10
    y    -10
    z    -10

    parent_id 200
  end

  factory :star1_location, parent: :location do
    id   400
    x    10
    y    10
    z    10

    parent_id 300
  end

  factory :jump_gate1_location, parent: :location do
    id   500
    x    10
    y    10
    z    10

    parent_id 300
  end

  factory :planet1_location, parent: :location do
    id   600
    x    10
    y    10
    z    10

    parent_id 300
    movement_strategy \
      Motel::MovementStrategies::Elliptical.new(
        :relative_to => Motel::MovementStrategies::Elliptical::RELATIVE_TO_FOCI,
        :speed => 0.1, :eccentricity => 0.6, :semi_latus_rectum => 150,
        :direction => Motel.random_axis)
  end

  factory :ast1_location, parent: :location do
    id   700
    x    10
    y    10
    z    10

    parent_id 300
  end

  factory :moon1_location, parent: :location do
    id   800
    x    10
    y    10
    z    10

    parent_id 500
  end

  factory :station1_location, parent: :location do
    id   900
    x    10
    y    10
    z    10

    parent_id 300
  end

  factory :ship1_location, parent: :location do
    id   1000
    x    10
    y    10
    z    10

    parent_id 300
  end

  factory :ship2_location, parent: :location do
    id   1001
    x    10
    y    10
    z    10

    parent_id 300
  end

end
