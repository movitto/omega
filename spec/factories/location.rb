require 'motel/location'
require 'motel/movement_strategies/stopped'
require 'motel/movement_strategies/elliptical'

FactoryGirl.define do
  factory 'motel/location' do
    server_entity
    create_method 'motel::create_location'

    x  0
    y  0
    z  0
    orientation_x 0
    orientation_y 0
    orientation_z 1
    parent_id nil

    factory :location do
      sequence(:id, 10000)

      x { Kernel.rand(-1000...1000) }
      y { Kernel.rand(-1000...1000) }
      z { Kernel.rand(-1000...1000) }
      orientation { Motel.rand_vector }
    end
  end
end
