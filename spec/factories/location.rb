require 'motel/runner'
require 'motel/location'
require 'motel/movement_strategies/stopped'
require 'motel/movement_strategies/elliptical'

FactoryGirl.define do
  factory :server_location, class: Motel::Location do
    x  0
    y  0
    z  0
    parent_id nil

    after(:build) { |l| Motel::Runner.instance.run(l) }
  end

  factory :unv_location, parent: :server_location do
    id 100
  end

  factory :gal1_location, parent: :server_location do
    id   200
    x    10
    y    10
    z    10

    parent_id 100
  end
  
  factory :sys1_location, parent: :server_location do
    id   300
    x    10
    y    10
    z    10

    parent_id 200
  end

  factory :sys2_location, parent: :server_location do
    id   301
    x    -10
    y    -10
    z    -10

    parent_id 200
  end

  factory :sys3_location, parent: :server_location do
    id   302
    x    -10
    y    -10
    z    -10

    parent_id 200
  end

  factory :star1_location, parent: :server_location do
    id   400
    x    10
    y    10
    z    10

    parent_id 300
  end

  factory :jump_gate1_location, parent: :server_location do
    id   500
    x    150
    y    150
    z    150

    parent_id 300
  end

  factory :planet1_location, parent: :server_location do
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

  factory :ast1_location, parent: :server_location do
    id   700
    x    10
    y    10
    z    10

    parent_id 300
  end

  factory :ast2_location, parent: :server_location do
    id   701
    x    -12
    y    -43
    z     76

    parent_id 300
  end

  factory :moon1_location, parent: :server_location do
    id   800
    x    10
    y    10
    z    10

    parent_id 500
  end

  factory :station1_location, parent: :server_location do
    id   900
    x    -100
    y    -100
    z    -100

    parent_id 300
  end

  factory :station2_location, parent: :server_location do
    id   901
    x    150
    y    150
    z    150

    parent_id 301
  end

  factory :station3_location, parent: :server_location do
    id   902
    x    70
    y    70
    z    70

    parent_id 300
  end

  factory :station4_location, parent: :server_location do
    id   903
    x    102
    y    106
    z    103

    parent_id 300
  end

  factory :station5_location, parent: :server_location do
    id   904
    x    -109
    y    -110
    z    -108

    parent_id 300
  end

  factory :ship1_location, parent: :server_location do
    id   1000
    x    10
    y    10
    z    10

    parent_id 300
  end

  factory :ship2_location, parent: :server_location do
    id   1001
    x    60
    y    60
    z    60

    parent_id 300
  end

  factory :ship3_location, parent: :server_location do
    id   1002
    x     150
    y     150
    z     150

    parent_id 300
  end

  factory :ship4_location, parent: :server_location do
    id   1003
    x     -75
    y     121
    z     124

    parent_id 300
  end

  factory :ship5_location, parent: :server_location do
    id   1004
    x     -98
    y     135
    z     145

    parent_id 300
  end

  factory :ship6_location, parent: :server_location do
    id   1005
    x     -95
    y     130
    z     140

    parent_id 300
  end

  # 2000's reserved for locations in actual specs

end
