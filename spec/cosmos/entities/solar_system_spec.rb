# solar_system module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/entities/solar_system'
require 'motel/movement_strategies/linear'

module Cosmos::Entities
describe SolarSystem do
  before(:each) do
    @s = build(:solar_system)
    @st1 = build(:star, :solar_system => @s)
    @st2 = build(:star, :solar_system => @s)
    @pl1 = build(:planet, :solar_system => @s)
    @pl2 = build(:planet, :solar_system => @s)
    @jg1 = build(:jump_gate, :solar_system => @s)
    @jg2 = build(:jump_gate, :solar_system => @s)
    @ast1 = build(:asteroid, :solar_system => @s)
    @ast2 = build(:asteroid, :solar_system => @s)
    @s << @st1
    @s << @st2
    @s << @pl1
    @s << @pl2
    @s << @jg1
    @s << @jg2
    @s << @ast1
    @s << @ast2
  end

  describe "#stars" do
    it "returns child stars" do
      @s.stars.should == [@st1, @st2]
    end
  end

  describe "#star" do
    it "returns first child star" do
      @s.star.should == @st1
    end
  end

  describe "#planets" do
    it "returns child planets" do
      @s.planets.should == [@pl1, @pl2]
    end
  end

  describe "#jump_gates" do
    it "returns child jump_gates" do
      @s.jump_gates.should == [@jg1, @jg2]
    end
  end

  describe "#asteroids" do
    it "returns child asteroids" do
      @s.asteroids.should == [@ast1, @ast2]
    end
  end

  describe "#initialize" do
    it "initializes entity" do
      args = {}
      SolarSystem.any_instance.should_receive(:init_entity).with(args)
      SolarSystem.new args
    end

    it "initializes env entity" do
      args = {}
      SolarSystem.any_instance.should_receive(:init_env_entity).with(args)
      SolarSystem.new args
    end
  end

  describe "#valid?" do
    context "entity not valid" do
      it "returns false" do
        s = SolarSystem.new
        s.should_receive(:entity_valid?).and_return(false)
        s.should_not be_valid
      end
    end

    context "location not stopped" do
      it "returns false" do
        s = SolarSystem.new
        s.should_receive(:entity_valid?).and_return(true)
        s.location.movement_strategy = Motel::MovementStrategies::Linear.new
        s.should_not be_valid
      end
    end

    it "returns true" do
      s = SolarSystem.new
      s.should_receive(:entity_valid?).and_return(true)
      s.should be_valid
    end
  end

  describe "#to_json" do
    it "returns solar system in json format" do
      g = build(:galaxy)
      s = SolarSystem.new(:id => 'solar_system1',
                          :name => 'solar_system1', :galaxy => g,
                          :location => Motel::Location.new(:x => 50))
      s.add_child(build(:planet))

      j = s.to_json
      j.should include('"json_class":"Cosmos::Entities::SolarSystem"')
      j.should include('"id":"solar_system1"')
      j.should include('"name":"solar_system1"')
      j.should include('"json_class":"Motel::Location"')
      j.should include('"x":50')
      j.should include('"parent_id":"'+g.id+'"')
      j.should include('"json_class":"Cosmos::Entities::Planet"')
      j.should include('"id":"'+s.planets.first.id+'"')
    end
  end

  describe "#json_create" do
    it "returns solar system from json format" do
      j = '{"json_class":"Cosmos::Entities::SolarSystem","data":{"id":"solar_system1","name":"solar_system1","location":{"json_class":"Motel::Location","data":{"id":null,"x":50.0,"y":null,"z":null,"orientation_x":null,"orientation_y":null,"orientation_z":null,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"children":[{"json_class":"Cosmos::Entities::Planet","data":{"id":"planet23","name":"planet23","location":{"json_class":"Motel::Location","data":{"id":10089,"x":-273,"y":-655,"z":432,"orientation_x":0,"orientation_y":0,"orientation_z":1,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"children":[],"metadata":{},"parent_id":"solar_system1","color":"AABBCC","size":55}}],"metadata":{},"parent_id":"galaxy12","background":0}}'
      s = RJR.parse_json(j)

      s.class.should == Cosmos::Entities::SolarSystem
      s.name.should == 'solar_system1'
      s.location.x.should  == 50
      s.planets.size.should == 1
    end
  end

end # describe SolarSystem::Entities
end # module Cosmos
