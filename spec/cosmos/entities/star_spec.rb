# star module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/entities/star'
require 'motel/movement_strategies/linear'

module Cosmos::Entities
describe Star do
  describe "#initialize" do
    it "initializes entity" do
      args = {}
      Star.any_instance.should_receive(:init_entity).with(args)
      Star.new args
    end

    it "initializes system entity" do
      args = {}
      Star.any_instance.should_receive(:init_system_entity).with(args)
      Star.new args
    end
  end

  describe "#valid?" do
    context "entity not valid" do
      it "returns false" do
        s = Star.new
        s.should_receive(:entity_valid?).and_return(false)
        s.should_not be_valid
      end
    end

    context "system entity not valid" do
      it "returns false" do
        s = Star.new
        s.should_receive(:entity_valid?).and_return(true)
        s.should_receive(:system_entity_valid?).and_return(false)
        s.should_not be_valid
      end
    end

    context "location not stopped" do
      it "returns false" do
        s = Star.new
        s.should_receive(:entity_valid?).and_return(true)
        s.should_receive(:system_entity_valid?).and_return(true)
        s.location.movement_strategy = Motel::MovementStrategies::Linear.new
        s.should_not be_valid
      end
    end

    it "returns true" do
      s = Star.new
      s.should_receive(:entity_valid?).and_return(true)
      s.should_receive(:system_entity_valid?).and_return(true)
      s.should be_valid
    end
  end

  describe "#to_json" do
    it "returns star in json format" do
      s = Star.new(:name => 'star1',
                   :location => Motel::Location.new(:x => 50))

      j = s.to_json
      j.should include('"json_class":"Cosmos::Entities::Star"')
      j.should include('"name":"star1"')
      j.should include('"json_class":"Motel::Location"')
      j.should include('"x":50')
    end
  end

  describe "#json_create" do
    it "returns star from json format" do
      j = '{"data":{"color":"FFFF00","size":49,"name":"star1","location":{"data":{"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"z":null,"parent_id":null,"x":50,"restrict_view":true,"id":null,"restrict_modify":true,"y":null},"json_class":"Motel::Location"}},"json_class":"Cosmos::Entities::Star"}'
      s = JSON.parse(j)

      s.class.should == Cosmos::Entities::Star
      s.name.should == 'star1'
      s.location.x.should  == 50
    end
  end

end # describe Star
end # module Cosmos::Entities
