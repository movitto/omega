# entity module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'ostruct'
require 'spec_helper'
require 'manufactured/ship'
require 'motel/movement_strategies/linear'

module Manufactured::Entity
describe InSystem do
  def build_entity
    e = OpenStruct.new
    e.extend(InSystem)
    e.location = build(:location)
    e
  end

  before(:each) do
    @e = build_entity
  end

  describe "#location=" do
    context "location.parent_id == solar_system.location.id" do
      it "sets parent location" do
        @e.solar_system = build(:solar_system)
        @e.location = build(:location, :parent_id => @e.solar_system.location.id)
        @e.location.parent.should == @e.solar_system.location
      end
    end

    context "location's parent is different than solar_system's location" do
      it "does not set parent" do
        @e.solar_system = build(:solar_system)
        @e.location = build(:location)
        @e.location.parent.should be_nil
      end
    end
  end

  describe "#solar_system=" do
    it "sets solar system" do
      sys = build(:solar_system)
      @e.solar_system = sys
      @e.solar_system.should == sys
    end

    it "sets system_id" do
      sys = build(:solar_system)
      @e.solar_system = sys
      @e.system_id.should == sys.id
    end

    it "sets location parent" do
      sys = build(:solar_system)
      @e.solar_system = sys
      @e.location.parent.should == sys.location
    end
  end

end # describe InSystem

describe HasCargo do
  def build_entity
    e = OpenStruct.new
    e.extend(HasCargo)
    e.id = rand
    e.resources = []
    e.cargo_capacity = 100
    e.location = build(:location)
    e
  end

  before(:each) do
    @e = build_entity
  end

  describe "#resources_valid?" do
    context "resources are invalid" do
      it "returns false" do
        @e.resources = ['false']
        @e.resources_valid?.should be_false
      end
    end

    context "resources are valid" do
      it "returns false" do
        @e.resources = [build(:resource)]
        @e.resources_valid?.should be_true
      end
    end
  end

  describe "#cargo_empty?" do
    context "cargo quantity == 0" do
      it "returns true" do
        @e.cargo_empty?.should be_true
      end
    end

    context "cargo quantity > 0" do
      it "returns false" do
        @e.add_resource Cosmos::Resource.new :quantity => 50
        @e.cargo_empty?.should be_false
      end
    end
  end

  describe "#cargo_full?" do
    context "cargo quantity == cargo capacity" do
      it "returns true" do
        res = build(:resource, :quantity => @e.cargo_capacity)
        @e.add_resource res
        @e.cargo_full?.should be_true
      end
    end

    context "cargo quantity != cargo capacity" do
      it "returns false" do
        res = build(:resource, :quantity => @e.cargo_capacity - 100)
        @e.add_resource res
        @e.cargo_full?.should be_false
      end
    end
  end

  describe "#cargo_space" do
    it "returns cargo capacity - cargo quantity" do
      res = build(:resource, :quantity => @e.cargo_capacity - 10)
      @e.add_resource res
      @e.cargo_space.should == 10
    end
  end

  describe "#add_resource" do
    context "cannot accept resource" do
      it "raises an RuntimeError" do
        res = build(:resource, :quantity => @e.cargo_capacity)
        @e.resources = [res]
        lambda{
          @e.add_resource res
        }.should raise_error(RuntimeError)
      end
    end

    it "adds resource to entity" do
      r = build(:resource, :quantity => @e.cargo_capacity)
      lambda{
        @e.add_resource r
      }.should change{@e.resources.size}.by(1)
      @e.resources.find { |rs| rs == r }.should_not be_nil
    end

    it "sets entity on resource" do
      r = build(:resource, :quantity => @e.cargo_capacity)
      @e.add_resource r
      r.entity.should == @e
    end
  end

  describe "#remove_resource" do
    context "ship does not have resource" do
      it "raises an RuntimeError" do
        r = build(:resource, :quantity => @e.cargo_capacity / 2)

        lambda{
          @e.remove_resource r
        }.should raise_error(RuntimeError)

        @e.add_resource r

        lambda{
          @e.remove_resource r
        }.should_not raise_error(RuntimeError)
      end
    end

    it "removes resource from ship" do
      r = build(:resource, :quantity => @e.cargo_capacity)
      r1 = build(:resource,
                 :material_id => r.material_id,
                 :quantity => 3 * @e.cargo_capacity / 4)
      @e.add_resource r
      lambda{
        @e.remove_resource r1
      }.should_not change{@e.resources.size}

      @e.resources.first.quantity.should == @e.cargo_capacity / 4
      r1.quantity = @e.cargo_capacity / 4

      lambda{
        @e.remove_resource r1
      }.should change{@e.resources.size}.by(-1)
    end
  end

  describe "#cargo_quantity" do
    it "returns total cargo quantity" do
      res1 = Cosmos::Resource.new :id => 'metal-steel', :quantity => 50
      res2 = Cosmos::Resource.new :id => 'metal-titanium', :quantity => 50
      @e.add_resource res1
      @e.add_resource res2
      @e.cargo_quantity.should == 100
    end
  end

  describe "#can_transfer?" do
    before(:each) do
      @sys1  = build(:solar_system)
      @sys2  = build(:solar_system)
      @e1    = build_entity

      @e.location.parent = @sys1.location
      @e1.location.parent = @sys1.location

      @e.transfer_distance = 100

      @res = Cosmos::Resource.new :id => 'metal-titanium', :quantity => 50
      @e.add_resource(@res)
    end

    it "returns true" do
      @e.can_transfer?(@e1, @res).should be_true
    end

    context "entities are same" do
      it "returns false" do
        @e.can_transfer?(@e, @res).should be_false
      end
    end

    context "quantity exceeds that held" do
      it "returns false" do
        res = build(:resource, :id => @res.id, :quantity => 500)
        @e.can_transfer?(@e1, res).should be_false
      end
    end

    context "ship does not have resource" do
      it "returns false" do
        res = build(:resource, :id => 'gem-diamond', :quantity => 5)
        @e.can_transfer?(@e1, res).should be_false
      end
    end

    context "ships in different systems" do
      it "returns false" do
        @e.location.parent = @sys2.location
        @e.can_transfer?(@e1, @res).should be_false
      end
    end

    context "ships too far away" do
      it "returns false" do
        @e.location.x = @e1.location.x + @e.transfer_distance * 2
        @e.can_transfer?(@e1, @res).should be_false
      end
    end
  end

  describe "#can_accept?" do
    before(:each) do
      @r = Cosmos::Resource.new :id => 'metal-titanium'
    end

    context "cargo capacity would be exceeded" do
      it "returns false" do
        @r.quantity = 500
        @e.can_accept?(@r).should be_false
      end
    end

    it "returns true" do
      @r.quantity = 50
      @e.can_accept?(@r).should be_true
    end
  end

end # describe HasCargo
end # module Manufactured::Entity
