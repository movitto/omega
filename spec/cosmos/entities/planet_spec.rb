# planet module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/entities/planet'
require 'cosmos/entities/moon'

module Cosmos::Entities
describe Planet do
  describe "#initialize" do
    it "initializes entity" do
      args = {}
      Planet.any_instance.should_receive(:init_entity).with(args)
      Planet.new args
    end

    it "initializes system entity" do
      args = {}
      Planet.any_instance.should_receive(:init_system_entity).with(args)
      Planet.new args
    end
  end

  describe "#valid?" do
    context "entity not valid" do
      it "returns false" do
        p = Planet.new
        p.should_receive(:entity_valid?).and_return(false)
        p.should_not be_valid
      end
    end

    context "system entity not valid" do
      it "returns false" do
        p = Planet.new
        p.should_receive(:entity_valid?).and_return(true)
        p.should_receive(:system_entity_valid?).and_return(false)
        p.should_not be_valid
      end
    end

    it "returns true" do
      p = Planet.new
      p.should_receive(:entity_valid?).and_return(true)
      p.should_receive(:system_entity_valid?).and_return(true)
      p.should be_valid
    end
  end

  describe "#to_json" do
    it "returns planet in json format" do
      p = Planet.new(:id => 'planet1', :name => 'planet1',
                     :location => Motel::Location.new(:x => 50))
      p.add_child(build(:moon, :planet => p))

      j = p.to_json
      j.should include('"json_class":"Cosmos::Entities::Planet"')
      j.should include('"id":"planet1"')
      j.should include('"name":"planet1"')
      j.should include('"json_class":"Motel::Location"')
      j.should include('"x":50')
      j.should include('"json_class":"Cosmos::Entities::Moon"')
      j.should include('"name":"moon1"')
    end
  end

  describe "#json_create" do
    it "returns planet from json format" do
      j = '{"json_class":"Cosmos::Entities::Planet","data":{"id":"planet1","name":"planet1","location":{"json_class":"Motel::Location","data":{"id":null,"x":50.0,"y":null,"z":null,"orientation_x":null,"orientation_y":null,"orientation_z":null,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"children":[{"json_class":"Cosmos::Entities::Moon","data":{"id":"moon1","name":"moon1","location":{"json_class":"Motel::Location","data":{"id":10000,"x":759,"y":-771,"z":-817,"orientation_x":0,"orientation_y":0,"orientation_z":1,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"children":[],"metadata":{},"parent_id":"planet1"}}],"metadata":{},"parent_id":null,"color":"fe58cd","size":51}}'
      p = RJR::JSONParser.parse(j)

      p.class.should == Cosmos::Entities::Planet
      p.name.should == 'planet1'
      p.location.x.should  == 50
      p.moons.size.should == 1
      p.moons.first.name.should == 'moon1'
    end
  end

end # describe Planet
end # module Cosmos
