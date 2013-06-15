# galaxy module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/movement_strategies/linear'

module Cosmos::Entities
describe Galaxy do
  describe "#initialize" do
    it "initializes entity" do
      args = {}
      Galaxy.any_instance.should_receive(:init_entity).with(args)
      Galaxy.new args
    end

    it "initializes env entity" do
      args = {}
      Galaxy.any_instance.should_receive(:init_env_entity).with(args)
      Galaxy.new args
    end
  end

  describe "#valid?" do
    context "entity not valid" do
      it "returns false" do
        g = Galaxy.new
        g.should_receive(:entity_valid?).and_return(false)
        g.should_not be_valid
      end
    end

    context "location not stopped" do
      it "returns false" do
        g = Galaxy.new
        g.should_receive(:entity_valid?).and_return(true)
        g.location.movement_strategy = Motel::MovementStrategies::Linear.new
        g.should_not be_valid
      end
    end

    it "returns true" do
      g = Galaxy.new
      g.should_receive(:entity_valid?).and_return(true)
      g.should be_valid
    end
  end

  describe "#to_json" do
    it "returns galaxy in json format" do
      g = Galaxy.new(:name => 'galaxy1',
                             :location => Motel::Location.new(:x => 50))
      g.add_child(build(:solar_system))

      j = g.to_json
      j.should include('"json_class":"Cosmos::Entities::Galaxy"')
      j.should include('"name":"galaxy1"')
      j.should include('"json_class":"Motel::Location"')
      j.should include('"x":50')
      j.should include('"json_class":"Cosmos::Entities::SolarSystem"')
      j.should include('"id":"'+g.solar_systems.first.id+'"')
    end
  end

  describe "#json_create" do
    it "returns galaxy from json format" do
      j = '{"json_class":"Cosmos::Entities::Galaxy","data":{"id":null,"name":"galaxy1","location":{"json_class":"Motel::Location","data":{"id":null,"x":50.0,"y":null,"z":null,"orientation_x":null,"orientation_y":null,"orientation_z":null,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"children":[{"json_class":"Cosmos::Entities::SolarSystem","data":{"id":"system1","name":"system1","location":{"json_class":"Motel::Location","data":{"id":10000,"x":444,"y":-948,"z":-771,"orientation_x":0,"orientation_y":0,"orientation_z":1,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"children":[],"metadata":{},"parent_id":null,"background":4}}],"metadata":{},"parent_id":null,"background":3}}'
      g = JSON.parse(j)

      g.class.should == Cosmos::Entities::Galaxy
      g.name.should == 'galaxy1'
      g.location.x.should  == 50
      g.solar_systems.size.should == 1
      g.solar_systems.first.name.should == 'system1'
    end
  end

end # describe Galaxy
end # module Cosmos::Entities
