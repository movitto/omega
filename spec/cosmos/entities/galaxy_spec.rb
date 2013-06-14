# galaxy module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

module Cosmos
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
      g = Cosmos::Galaxy.new(:name => 'galaxy1',
                             :location => Motel::Location.new(:x => 50))
      g.add_child(Cosmos::SolarSystem.new(:name => 'system1'))

      j = g.to_json
      j.should include('"json_class":"Cosmos::Galaxy"')
      j.should include('"name":"galaxy1"')
      j.should include('"json_class":"Motel::Location"')
      j.should include('"x":50')
      j.should include('"json_class":"Cosmos::SolarSystem"')
      j.should include('"name":"system1"')
    end
  end

  describe "#json_create" do
    it "returns galaxy from json format" do
      j = '{"data":{"background":"galaxy4","name":"galaxy1","solar_systems":[{"data":{"background":"system5","planets":[],"jump_gates":[],"name":"system1","star":null,"location":{"data":{"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"z":0,"parent_id":null,"x":0,"restrict_view":true,"id":null,"restrict_modify":true,"y":0},"json_class":"Motel::Location"}},"json_class":"Cosmos::SolarSystem"}],"location":{"data":{"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"z":null,"parent_id":null,"x":50,"restrict_view":true,"id":null,"restrict_modify":true,"y":null},"json_class":"Motel::Location"}},"json_class":"Cosmos::Galaxy"}'
      g = JSON.parse(j)

      g.class.should == Cosmos::Galaxy
      g.name.should == 'galaxy1'
      g.location.x.should  == 50
      g.solar_systems.size.should == 1
      g.solar_systems.first.name.should == 'system1'
    end
  end

end # describe Galaxy
end # module Cosmos
