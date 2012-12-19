require 'cosmos/asteroid'

FactoryGirl.define do
  factory :server_asteroid, class: Cosmos::Asteroid do
    ignore do
      solar_system :sys1
    end

    after(:build) { |a,e|
      FactoryGirl.build(e.solar_system)
      s = Cosmos::Registry.instance.find_entity(:name => e.solar_system.to_s)
      s.add_child(a) unless s.has_child?(a.name)
    }
  end

  factory :asteroid1, parent: :server_asteroid do
    name     'ast1'
    color    'FFEEDD'
    size      20

    association :location, factory: :ast1_location, :strategy => :build

    after(:build) { |ast|
      Cosmos::Registry.instance.set_resource(ast.name,
           Cosmos::Resource.new(:name => 'steel', :type => 'metal'), 500)
    }
  end

  #factory :asteroid2, parent: :server_asteroid do
  #  name     'ast2'
  #  color    'AABBCC'
  #  size      25

  #  association :location, factory: :ast2_location, :strategy => :build
  #end
end
