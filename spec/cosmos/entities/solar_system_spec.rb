# solar_system module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/entities/solar_system'

module Cosmos
describe SolarSystem do
  before(:each) do
    @st1 = build(:star)
    @st2 = build(:star)
    @pl1 = build(:planet)
    @pl2 = build(:planet)
    @jg1 = build(:jump_gate)
    @jg2 = build(:jump_gate)
    @ast1 = build(:asteroid)
    @ast2 = build(:asteroid)
    @s = SolarSystem.new
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
      SolarSystem.any_instance.should_receive(:init_system_entity).with(args)
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
      s.should_not be_valid
    end
  end

  describe "#to_json" do
    it "returns solar system in json format" do
      g = Cosmos::Galaxy.new(:name => 'galaxy1')
      s = Cosmos::SolarSystem.new(:name => 'solar_system1', :galaxy => g,
                             :location => Motel::Location.new(:x => 50))
      s.add_child(Cosmos::Planet.new(:name => 'planet1'))

      j = s.to_json
      j.should include('"json_class":"Cosmos::SolarSystem"')
      j.should include('"name":"solar_system1"')
      j.should include('"json_class":"Motel::Location"')
      j.should include('"x":50')
      j.should include('"galaxy_name":"galaxy1"')
      j.should include('"json_class":"Cosmos::Planet"')
      j.should include('"name":"planet1"')
    end
  end

  describe "#json_create" do
    it "returns solar system from json format" do
      j = '{"json_class":"Cosmos::SolarSystem","data":{"star":null,"planets":[{"json_class":"Cosmos::Planet","data":{"moons":[],"color":"21f798","size":14,"name":"planet1","location":{"json_class":"Motel::Location","data":{"z":0,"restrict_view":true,"x":0,"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"parent_id":null,"id":null,"y":0}}}}],"name":"solar_system1","jump_gates":[],"background":"system5","location":{"json_class":"Motel::Location","data":{"z":null,"restrict_view":true,"x":50,"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"parent_id":null,"id":null,"y":null}}}}'
      s = JSON.parse(j)

      s.class.should == Cosmos::SolarSystem
      s.name.should == 'solar_system1'
      s.location.x.should  == 50
      s.planets.size.should == 1
      s.planets.first.name.should == 'planet1'
    end
  end

end # describe SolarSystem
end # module Cosmos
