# asteroid module tests
#
# Copyright (C) 2012-2013-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/resource'
require 'cosmos/entities/asteroid'
require 'motel/movement_strategies/linear'

module Cosmos::Entities
describe Asteroid do
  describe "#initialize" do
    it "initializes entity" do
      args = {}
      Asteroid.any_instance.should_receive(:init_entity).with(args)
      a = Asteroid.new args
    end

    it "initializes system entity" do
      args = {}
      Asteroid.any_instance.should_receive(:init_system_entity).with(args)
      a = Asteroid.new args
    end

    it "initializes resources" do
      a = Asteroid.new
      a.resources.should == []
    end
  end

  describe "#valid?" do
    context "entity not valid" do
      it "returns false" do
        a = Asteroid.new
        a.should_receive(:entity_valid?).and_return(false)
        a.should_not be_valid
      end
    end

    context "system entity not valid" do
      it "returns false" do
        a = Asteroid.new
        a.should_receive(:entity_valid?).and_return(true)
        a.should_receive(:system_entity_valid?).and_return(false)
        a.should_not be_valid
      end
    end

    context "location not stopped" do
      it "returns false" do
        a = Asteroid.new
        a.should_receive(:entity_valid?).and_return(true)
        a.should_receive(:system_entity_valid?).and_return(true)
        a.location.movement_strategy = Motel::MovementStrategies::Linear.new
        a.should_not be_valid
      end
    end

    context "invalid resources" do
      it "returns false" do
        r = Cosmos::Resource.new
        a = Asteroid.new :resources => [r]
        a.should_receive(:entity_valid?).and_return(true)
        a.should_receive(:system_entity_valid?).and_return(true)
        r.should_receive(:valid?).and_return(false)
        a.should_not be_valid
      end
    end

    it "returns true" do
      a = Asteroid.new
      a.should_receive(:entity_valid?).and_return(true)
      a.should_receive(:system_entity_valid?).and_return(true)
      a.should be_valid
    end
  end

  describe "#accepts_resource?" do
    context "resource not valid" do
      it "returns false" do
        r = Cosmos::Resource.new
        r.should_receive(:valid?).and_return(false)
        a = Asteroid.new
        a.accepts_resource?(r).should be_false
      end
    end

    it "returns true" do
      r = Cosmos::Resource.new
      r.should_receive(:valid?).and_return(true)
      a = Asteroid.new
      a.accepts_resource?(r).should be_true
    end
  end

  describe "#set_resource" do
    context "entity has resource" do
      it "updates resource" do
        a = Asteroid.new
        r = build(:resource, :quantity => 20)
        r1 = build(:resource, :material_id => r.material_id, :quantity => 10)
        a.set_resource r
        a.set_resource r1
        a.resources.first.quantity.should == r1.quantity
      end

      context "new quantity is 0" do
        it "deletes resource" do
          a = Asteroid.new
          r = build(:resource, :quantity => 20)
          r1 = build(:resource, :material_id => r.material_id, :quantity => 0)
          a.set_resource r
          a.set_resource r1
          a.resources.should be_empty
        end
      end
    end

    it "adds resource to asteroid" do
      a = Asteroid.new
      r = build(:resource, :quantity => 20)
      a.set_resource r
      a.resources.size.should == 1
      a.resources.first.should == r
    end

    it "sets entity on resource" do
      a = Asteroid.new
      r = build(:resource, :quantity => 20)
      a.set_resource r
      r.entity.should == a
    end
  end

  describe "#to_json" do
    it "returns asteroid in json format" do
      a = Asteroid.new :name => 'asteroid1', :color => 'brown', :size => 50,
                       :location => Motel::Location.new(:x => 50)
      a.set_resource Cosmos::Resource.new :id => 'metal-steel', :quantity => 50

      j = a.to_json
      j.should include('"json_class":"Cosmos::Entities::Asteroid"')
      j.should include('"name":"asteroid1"')
      j.should include('"color":"brown"')
      j.should include('"size":50')
      j.should include('"resources":[{"json_class":"Cosmos::Resource"')
      j.should include('"id":"metal-steel"')
      j.should include('"quantity":50')
      j.should include('"json_class":"Motel::Location"')
      j.should include('"x":50')
    end
  end

  describe "#json_create" do
    it "returns asteroid from json format" do
      j = '{"data":{"color":"brown","size":50,"name":"asteroid1","location":{"data":{"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"parent_id":null,"y":null,"z":null,"x":50,"restrict_view":true,"id":null,"restrict_modify":true},"json_class":"Motel::Location"}},"json_class":"Cosmos::Entities::Asteroid"}'
      a = JSON.parse(j)

      a.class.should == Cosmos::Entities::Asteroid
      a.name.should == 'asteroid1'
      a.color.should == 'brown'
      a.size.should == 50
      a.location.x.should  == 50
    end
  end

end # describe Asteroid
end # module Cosmos
