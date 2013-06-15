# moon module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/entities/moon'
require 'motel/movement_strategies/linear'

module Cosmos::Entities
describe Moon do
  describe "#initialize" do
    it "initializes entity" do
      args = {}
      Moon.any_instance.should_receive(:init_entity).with(args)
      Moon.new args
    end
  end

  describe "#valid?" do
    context "entity not valid" do
      it "returns false" do
        m = Moon.new
        m.should_receive(:entity_valid?).and_return(false)
        m.should_not be_valid
      end
    end

    context "location not stopped" do
      it "returns false" do
        m = Moon.new
        m.should_receive(:entity_valid?).and_return(true)
        m.location.movement_strategy = Motel::MovementStrategies::Linear.new
        m.should_not be_valid
      end
    end

    it "returns true" do
      m = Moon.new
      m.should_receive(:entity_valid?).and_return(true)
      m.should be_valid
    end
  end

  describe "#to_json" do
    it "returns moon in json format" do
      m = Moon.new(:name => 'moon1',
                   :location => Motel::Location.new(:x => 50))

      j = m.to_json
      j.should include('"json_class":"Cosmos::Entities::Moon"')
      j.should include('"name":"moon1"')
      j.should include('"json_class":"Motel::Location"')
      j.should include('"x":50')
    end
  end

  describe "#json_create" do
    it "returns moon from json format" do
      j = '{"data":{"name":"moon1","location":{"data":{"parent_id":null,"z":null,"restrict_view":true,"x":50,"restrict_modify":true,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"id":null,"y":null},"json_class":"Motel::Location"}},"json_class":"Cosmos::Entities::Moon"}'
      m = JSON.parse(j)

      m.class.should == Cosmos::Entities::Moon
      m.name.should == 'moon1'
      m.location.x.should  == 50
    end
  end

end # describe Moon
end # module Cosmos
