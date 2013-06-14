# planet module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/entities/planet'

module Cosmos
describe Planet do
  describe "#initialize" do
    it "initializes entity" do
      args = {}
      Planet.any_instance.should_receive(:init_entity).with(args)
      Planet.new args
    end

    it "initializes system entity" do
      args = {}
      Planet.any_instance.should_receive(:init_env_entity).with(args)
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
      p = Cosmos::Planet.new(:name => 'planet1',
                             :location => Motel::Location.new(:x => 50))
      p.add_child(Cosmos::Moon.new(:name => 'moon1'))

      j = g.to_json
      j.should include('"json_class":"Cosmos::Planet"')
      j.should include('"name":"planet1"')
      j.should include('"json_class":"Motel::Location"')
      j.should include('"x":50')
      j.should include('"json_class":"Cosmos::Moon"')
      j.should include('"name":"moon1"')
    end
  end

  describe "#json_create" do
    it "returns planet from json format" do
      j = '{"json_class":"Cosmos::Planet","data":{"moons":[{"json_class":"Cosmos::Moon","data":{"name":"moon1","location":{"json_class":"Motel::Location","data":{"z":0,"restrict_view":true,"x":0,"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"parent_id":null,"id":null,"y":0}}}}],"color":"e806c5","size":10,"name":"planet1","location":{"json_class":"Motel::Location","data":{"z":null,"restrict_view":true,"x":50,"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"parent_id":null,"id":null,"y":null}}}}'
      p = JSON.parse(j)

      p.class.should == Cosmos::Planet
      p.name.should == 'planet1'
      p.location.x.should  == 50
      p.moons.size.should == 1
      p.moons.first.name.should == 'moon1'
    end
  end

end # describe Planet
end # module Cosmos
