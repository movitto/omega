# loot module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/loot'
require 'rjr/common'

module Manufactured
describe Loot do
  describe "#initialize" do
    it "sets defaults" do
      l = Loot.new
      l.id.should be_nil
      l.resources.should == []
      l.solar_system.should be_nil
      l.system_id.should be_nil

      l.location.should be_an_instance_of(Motel::Location)
      l.location.coordinates.should == [0,0,1]
      l.location.orientation.should == [1,0,0]
    end

    it "sets attributes" do
      r = build(:resource)
      sys = build(:solar_system)
      loc = build(:location)
      l = Loot.new :id                  => 'loot1',
                   :resources           => [r],
                   :solar_system        => sys,
                   :location            =>   loc

      l.id.should == 'loot1'
      l.resources.should == [r]
      l.solar_system.should == sys
      l.system_id.should == sys.id
      l.location.should == loc
    end

    context "movement strategy specified" do
      it "assigns movement strategy to loot" do
        m = Motel::MovementStrategies::Linear.new
        l = Loot.new :movement_strategy => m
        l.location.movement_strategy.should == m
      end
    end
  end

  describe "#valid?" do
    before(:each) do
      @sys = build(:solar_system)
      @l   = Loot.new :id           => 'loot1',
                      :solar_system => @sys
    end

    it "returns true" do
      @l.should be_valid
    end
    
    context "id is invalid" do
      it "returns false" do
        @l.id = nil
        @l.should_not be_valid
      end
    end

    context "location is invalid" do
      it "returns false" do
        @l.location = nil
        @l.should_not be_valid
      end
    end

    context "movement strategy is invalid" do
      it "returns false" do
        @l.location.movement_strategy = nil
        @l.should_not be_valid
      end
    end

    context "system_id is nil" do
      it "returns false" do
        @l.system_id = nil
        @l.should_not be_valid
      end
    end

    context "solar system is invalid" do
      it "returns false" do
        @l.solar_system = build(:galaxy)
        @l.should_not be_valid
      end
    end
  end

  describe "#to_json" do
    it "returns loot in json format" do
      system1 = Cosmos::Entities::SolarSystem.new :id => 'system1'
      location= Motel::Location.new :id => 20, :y => -15
      res1    = build(:resource)

      l = Manufactured::Loot.new(:id => 'loot1', :solar_system => system1, 
                                 :location => location,
                                 :resources => {res1.id => 100})

      j = l.to_json
      j.should include('"json_class":"Manufactured::Loot"')
      j.should include('"id":"loot1"')
      j.should include('"'+res1.id+'":100')
      j.should include('"json_class":"Motel::Location"')
      j.should include('"id":20')
      j.should include('"y":-15')
      j.should include('"system_id":"system1"')
    end
  end

  describe "#json_create" do
    it "returns loot from json format" do
      j = '{"json_class":"Manufactured::Loot","data":{"id":"loot1","location":{"json_class":"Motel::Location","data":{"id":20,"x":0,"y":-15.0,"z":0,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"movement_callbacks":[],"proximity_callbacks":[]}},"system_id":"system1","resources":{"metal-titanium":100}}}'
      l = ::RJR.parse_json(j)

      l.class.should == Manufactured::Loot
      l.id.should == "loot1"
      l.resources.size.should == 1
      l.resources.first.first.should == "metal-titanium"
      l.resources.first.last.should == 100
      l.location.should_not be_nil
      l.location.y.should == -15
      l.system_id.should == "system1"
    end
  end

end # describe Loot
end # module Manufactured
