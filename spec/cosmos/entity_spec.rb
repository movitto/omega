# entity module tests
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'cosmos/entity'
require 'cosmos/entities/galaxy'
require 'cosmos/entities/planet'
require 'motel/movement_strategies/linear'

module Cosmos
describe Entity do
  before(:each) do
    @e = OmegaTest::CosmosEntity.new
  end
  
  describe "#movement_strategy=" do
    it "sets movement stategy on location" do
      m = Motel::MovementStrategies::Linear.new
      @e.location = Motel::Location.new
      @e.movement_strategy = m
      @e.location.movement_strategy.should == m
    end
  end
  
  describe "#parent=" do
    it "sets parent" do
      g = Entities::Galaxy.new
      @e.parent = g
      @e.parent.should == g
    end

    it "sets parent_id" do
      g = Entities::Galaxy.new
      @e.parent = g
      @e.parent_id.should == g.id
    end

    it "sets location parent" do
      g = Entities::Galaxy.new :location => Motel::Location.new
      @e.parent = g
      @e.location.parent.should == g.location
    end
  end
  
  describe "#init_entity" do
    it "sets default entity values" do
      @e.init_entity
      @e.id.should be_nil
      @e.parent_id.should be_nil
      @e.parent.should be_nil
      @e.children.should == []
      @e.metadata.should == {}
    end

    it "sets entity values" do
      l = Motel::Location.new
      p = Entities::Galaxy.new :id => 'g'
      c = Entities::Planet.new
      @e .init_entity :location => l,
                      :id => 42,
                      :parent_id => p.id,
                      :parent => p,
                      :children => [c],
                      :metadata => { :foo => :bar}
      @e.location.should == l
      @e.id.should == 42
      @e.parent_id.should == p.id
      @e.parent.should == p
      @e.children.should == [c]
      @e.metadata.should == { :foo => :bar }
    end
  
    context "location not specified" do
      it "creates location" do
        @e.init_entity
        @e.location.should_not be_nil
        @e.location.should be_an_instance_of(Motel::Location)
        @e.location.coordinates.should == [0,0,0]
        @e.location.orientation.should == [0,0,1]
      end
    end
  
    context "movement strategy specified" do
      it "assigns movement strategy to location" do
        m = Motel::MovementStrategies::Linear.new
        @e.init_entity :movement_strategy => m
        @e.location.movement_strategy.should == m
      end
    end
  end
  
  describe "#entity_valid?" do
    before(:each) do
      @e.id   = "entity_id"
      @e.name = "entity_name"
      @e.parent = OmegaTest::CosmosEntity.new :id => 'parent'
      @e.location = build(:location)
      @e.add_child OmegaTest::CosmosEntity.new :id => 'child',
                                               :name => 'child',
                                               :parent_id => @e.id,
                                               :location => build(:location)
    end

    context "id is invalid" do
      it "returns false" do
        @e.id = nil
        @e.entity_valid?.should be_false

        @e.id = 42
        @e.entity_valid?.should be_false

        @e.id = ''
        @e.entity_valid?.should be_false
      end
    end
  
    context "name is invalid" do
      it "returns false" do
        @e.name = nil
        @e.entity_valid?.should be_false

        @e.name = 42
        @e.entity_valid?.should be_false

        @e.name = ''
        @e.entity_valid?.should be_false
      end
    end
  
    context "parent_id is nil" do
      it "returns false" do
        @e.parent_id  = nil
        @e.entity_valid?.should be_false
      end
    end
  
    context "parent is invalid" do
      it "returns false" do
        @e.parent = Entities::Galaxy.new
        @e.entity_valid?.should be_false
      end
    end
  
    context "location is invalid" do
      it "returns false" do
        @e.location.id = nil
        @e.entity_valid?.should be_false
      end
    end
  
    context "children are invalid" do
      it "returns false" do
        @e.children = [:foo]
        @e.entity_valid?.should be_false
      end
    end
  
    it "returns true" do
      @e.entity_valid?.should be_true
    end
  end

  describe "#add_child" do
    before(:each) do
      @e = OmegaTest::CosmosEntity.new :id => 'entity'
      @e.init_entity
      @c = OmegaTest::CosmosEntity.new :id   => 'child',
                                       :name => 'child',
                                       :parent_id => @e.id,
                                       :location => build(:location)
    end

    context "entity has child" do
      it "raises ArgumentError" do
        @e.add_child @c
        lambda {
          @e.add_child @c
        }.should raise_error(ArgumentError)
      end
    end

    context "child not of valid type" do
      it "raises ArgumentError" do
        lambda {
          @e.add_child 42
        }.should raise_error(ArgumentError)
      end
    end

    it "sets parent_id of child's location" do
      @e.add_child @c
      @c.location.parent_id.should == @e.location.id
    end

    it "sets parent of child" do
      @e.add_child @c
      @c.parent.should == @e
    end

    it "stores child locally" do
      @e.add_child @c
      @e.children.should == [@c]
    end
    
    it "returns child" do
      @e.add_child(@c).should == @c
    end
  end
  
  describe "#remove_child" do
    before(:each) do
      @e = OmegaTest::CosmosEntity.new :id => 'entity'
      @c = OmegaTest::CosmosEntity.new :id => 'child',
                                       :name => 'child',
                                       :parent_id => @e.id,
                                       :location => build(:location)
      @e.add_child @c
    end

    it "removes child entity" do
      @e.remove_child @c
      @e.children.should be_empty
    end

    it "removes child id" do
      @e.remove_child @c.id
      @e.children.should be_empty
    end

    context "child not present" do
      it "does nothing" do
        c2 = OmegaTest::CosmosEntity.new
        @e.remove_child c2
        @e.children.should == [@c]
      end
    end
  end
  
  describe "#has_children?" do
    before(:each) do
      @e = OmegaTest::CosmosEntity.new :id => 'entity'
      @c = OmegaTest::CosmosEntity.new :id => 'child',
                                       :name => 'child',
                                       :parent_id => @e.id,
                                       :location => build(:location)
    end

    context "entity has children" do
      it "returns true" do
        @e.add_child @c
        @e.should have_children
      end
    end
  
    context "entity does not have children" do
      it "returns false" do
        @e.should_not have_children
      end
    end
  end
  
  describe "#has_child?" do
    before(:each) do
      @e = OmegaTest::CosmosEntity.new :id => 'entity'
      @c = OmegaTest::CosmosEntity.new :id => 'child',
                                       :name => 'child',
                                       :parent_id => @e.id,
                                       :location => build(:location)
    end

    context "entity has specified child" do
      it "returns true" do
        @e.add_child @c
        @e.should have_child(@c)
      end
    end
  
    context "entity has specified child id" do
      it "returns true" do
        @e.add_child @c
        @e.should have_child(@c.id)
      end
    end
  
    context "entity does not have specified child" do
      it "returns false" do
        c2 = OmegaTest::CosmosEntity.new
        @e.add_child @c
        @e.should_not have_child(c2)
      end
    end
  
    context "entity does not have specified child id" do
      it "returns false" do
        c2 = OmegaTest::CosmosEntity.new :id => 'c2'
        @e.add_child @c
        @e.should_not have_child(c2.id)
      end
    end
  end
  
  describe "#each_child" do
    it "calls block for each child with self and child" do
      c1 = OmegaTest::CosmosEntity.new
      c2 = OmegaTest::CosmosEntity.new
      @e.children = [c1,c2]

      p = proc { |a,b| }
      p.should_receive(:call).with(@e, c1)
      p.should_receive(:call).with(@e, c2)

      @e.each_child &p
    end

    it "calls each_child on each child" do
      c1 = OmegaTest::CosmosEntity.new
      c2 = OmegaTest::CosmosEntity.new
      @e.children = [c1,c2]

      p = proc { |a,b| }

      c1.should_receive(:each_child).with(&p)
      c2.should_receive(:each_child).with(&p)

      @e.each_child &p
    end
  end
  
  describe "#accepts_resource?" do
    it "returns false by default" do
      @e.accepts_resource?('whatever').should be_false
    end
  end
  
  describe "#to_s" do
    it "returns entity in string format" do
      @e.name = 'foobar'
      @e.to_s.should == "CosmosEntity-foobar"
    end
  end
  
  describe "#entity_json" do
    it "returns entity json attributes" do
      @e.id = 'foo'
      @e.name = 'bar'
      @e.location.id = 42
      c = OmegaTest::CosmosEntity.new :id => 'child'
      @e.children = [c]
      @e.metadata = { :foo => 'bar' }
      @e.parent_id = 'parent'
      @e.entity_json.should == {:id => 'foo',
                                :name => 'bar',
                                :location => @e.location,
                                :children => @e.children,
                                :metadata => { :foo => 'bar' },
                                :parent_id => 'parent'}
    end
  end
end # module Entity

describe EnvEntity do
  before(:each) do
    @e = OmegaTest::CosmosEnvEntity.new
  end

  describe "#init_env_entity" do
    it "sets default environment entity values" do
      @e.init_env_entity
      @e.background.should < OmegaTest::CosmosEnvEntity::NUM_BACKGROUNDS
      @e.background.should >= 0
    end

    it "sets environment entity values" do
      @e.init_env_entity :background => 5
      @e.background.should == 5
    end
  end
  
  describe "#env_entity_json" do
    it "returns environment entity json attributes" do
      @e.init_env_entity :background => 5
      j = @e.env_entity_json
      j.should == {:background => 5}
    end
  end
end # describe EnvEntity

describe SystemEntity do
  before(:each) do
    @e = OmegaTest::CosmosSystemEntity.new
  end

  describe "#init_system_entity" do
    it "uses rand generates to set default system entity values" do
      OmegaTest::CosmosSystemEntity::RAND_SIZE.should_receive(:call).and_return(4)
      OmegaTest::CosmosSystemEntity::RAND_COLOR.should_receive(:call).and_return(5)
      @e.init_system_entity
      @e.size.should == 4
      @e.color.should == 5
    end

    it "sets system entity values" do
      @e.init_system_entity :size => :foo, :color => :bar
      @e.size.should == :foo
      @e.color.should == :bar
    end
  end
  
  describe "#system_entity_valid?" do
    it "invokes validate_size to validate size" do
      @e.size = 5
      OmegaTest::CosmosSystemEntity::VALIDATE_SIZE.should_receive(:call).with(5)
      @e.system_entity_valid?
    end

    it "invokes validate_color to validate color" do
      @e.size = 5
      @e.color = 'c'
      OmegaTest::CosmosSystemEntity::VALIDATE_COLOR.should_receive(:call).with('c')
      @e.system_entity_valid?
    end

    context "invalid size" do
      it "returns false" do
        @e.size = nil
        @e.system_entity_valid?.should be_false

        @e.size = 5
        OmegaTest::CosmosSystemEntity::VALIDATE_SIZE.should_receive(:call).and_return(false)
        @e.system_entity_valid?.should be_false
      end
    end
  
    context "invalid color" do
      it "returns false" do
        @e.size = 5
        @e.color = 'c'
        OmegaTest::CosmosSystemEntity::VALIDATE_COLOR.should_receive(:call).and_return(false)
        @e.system_entity_valid?.should be_false
      end
    end
  end
  
  describe "#system_entity_json" do
    it "returns systemenvironment entity json attributes" do
      @e.size = 4
      @e.color = 5
      @e.system_entity_json.should == {:color => 5, :size => 4}
    end
  end
end # describe SystemEntity
end # module Cosmos
