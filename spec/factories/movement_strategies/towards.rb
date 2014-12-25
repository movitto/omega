require 'motel/movement_strategies/towards'

FactoryGirl.define do
  factory :ms_towards, :class => Motel::MovementStrategies::Towards do
    speed         1
    max_speed    10
    acceleration  3

    dir  [1, 0, 0]
    adir [1, 0, 0]

    rot_theta Math::PI/8
    rot_dir [0, 1, 0]

    target [0, 0, 0]
  end
end
