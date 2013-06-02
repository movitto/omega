# location module tests
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'motel/location'
require 'motel/movement_strategies/linear'
require 'motel/callbacks/movement'
require 'omega/server/callback'

module Motel
describe Location do
  describe "#parent_id=" do
    it "should set parent_id" do
      l = Location.new
      l.parent_id = 10
      l.parent_id.should == 10
    end

    context "changing parent id" do
      it "should nullify parent" do
        p = Location.new :id => 5
        l = Location.new :parent => p
        l.parent_id = 10
        l.parent.should be_nil
      end
    end
  end

  describe "#parent=" do
    before(:each) do
      @p = build(:location)
      @l = build(:location)
    end

    it "should set parent" do
      @l.parent = @p
      @l.parent.should == @p
    end

    it "should set parent id" do
      @l.parent = @p
      @l.parent_id.should == @p.id

      @l.parent = nil
      @l.parent_id.should == nil
    end
  end

  describe "#initialize" do
    it "sets default coordinates" do
      l = Location.new
      l.coordinates.should == [nil,nil,nil]
    end

    it "sets default orientation" do
      l = Location.new
      l.orientation.should == [nil,nil,nil]
    end

    it "sets stopped as default movement strategy" do
      l = Location.new
      l.movement_strategy.should == MovementStrategies::Stopped.instance
    end

    it "sets attributes" do
      p = Location.new :id => 2
      l = Location.new :id => 1,:parent => p,
                       :x => 3, :y => 4, :z => 5,
                       :orientation_x => 1,
                       :orientation_y => 0,
                       :orientation_z => 0
      l.id.should == 1
      l.parent_id.should == 2
      l.x.should == 3
      l.y.should == 4
      l.z.should == 5
      l.orientation_x.should == 1
      l.orientation_y.should == 0
      l.orientation_z.should == 0
      l.parent.should == p
      l.children.should == []
      l.callbacks.should == {}
      l.movement_strategy.should == Motel::MovementStrategies::Stopped.instance

      ms = OmegaTest::MovementStrategy.new
      l  = Location.new :movement_strategy => ms
      l.movement_strategy.should == ms

      # TODO coordinates, orientation, parent_id, callbacks, restrict, other params
    end

    [:x, :y, :z, :orientation_x, :orientation_y, :orientation_z].each { |p|
       it "converts #{p} to float" do
         l = Location.new p => "42"
         l.send(p).should == 42
       end
     }
  end

  describe "#update" do
    it "copies attributes" do
      p1 = Location.new
      p2 = Location.new :id => 10

      orig = Location.new :x => 1, :y => 2,
                          :orientation_z => -0.5,
                          :movement_strategy => 'foobar',
                          :parent_id => 5, :parent => p1

      nwl  = Location.new :x => 5, :orientation_y => -1,
                          :movement_strategy => 'foomoney',
                          :parent => p2

      orig.update(nwl)
      orig.x.should == 5
      orig.y.should == 2
      orig.z.should be_nil
      orig.orientation_x.should be_nil
      orig.orientation_y.should == -1
      orig.orientation_z.should == -0.5
      orig.movement_strategy.should == "foomoney"
      orig.parent_id.should == 10
      orig.parent.should be(p2)
    end

    it "skips nil attributes" do
      orig = Location.new :y => 6
      nwl  = Location.new
      nwl.y = nil

      orig.update(nwl)
      orig.y.should == 6
    end
  end

  describe "#valid" do
    context "id is nil" do
      it "returns false" do
        l = Location.new :coordinates => [0,0,0], :orientation => [0,0,1]
        l.should_not be_valid

        l.id = 1
        l.should be_valid

        l = Location.new(:id => 1, :coordinates => [0,0,0], :orientation => [0,0,1])
        l.should be_valid
      end
    end

    [:x, :y, :z, :orientation_x, :orientation_y, :orientation_z].each { |p|
      context "#{p} is not numeric" do
        it "returns false" do
          l = build(:location)
          l.send("#{p}=".intern, "42")
          l.should_not be_valid

          l.send("#{p}=".intern, 42)
          l.should be_valid
        end
      end
    }

    context "movement stategy is invalid" do
      it "returns false" do
        l = build(:location)
        l.movement_strategy = nil
        l.should_not be_valid

        l.movement_strategy = 42
        l.should_not be_valid

        l.movement_strategy = MovementStrategies::Linear.new :speed => nil
        l.should_not be_valid

        l.movement_strategy.speed = 5
        l.should be_valid
      end
    end
  end

  describe "#raise_event" do
    it "invokes registered event callbacks" do
      ran1 = ran2 = ran3 = false
      l = build(:location)
      l.callbacks['moved']  << Omega::Server::Callback.new { ran1 = true }
      l.callbacks['moved']  << Omega::Server::Callback.new { ran2 = true }
      l.callbacks['stopped'] << Omega::Server::Callback.new { ran3 = true }
      l.raise_event 'moved'
      ran1.should be_true
      ran2.should be_true
      ran3.should be_false
    end

    it "passes arguments to callbacks" do
      a = nil
      l = build(:location)
      l.callbacks['moved'] << Omega::Server::Callback.new { |arg| a = arg }
      l.raise_event 'moved', 42
      a.should == 42
    end

    context "callback#should_invoke? returns false" do
      it "skips callback" do
        ran1 = ran2 = false
        l = build(:location)
        l.callbacks['moved']  << Omega::Server::Callback.new(:only_if => proc { false }) { ran1 = true }
        l.callbacks['moved']  << Omega::Server::Callback.new { ran2 = true }
        l.raise_event 'moved'
        ran1.should be_false
        ran2.should be_true
      end
    end
  end

  describe "#coordinates" do
    it "returns array of coordinates" do
      l = Location.new :x => 1, :y => 2, :z => 3
      l.coordinates.should == [1,2,3]
    end
  end

  describe "#orientation" do
    it "returns array of orientation" do
      l = Location.new :orientation_x => 1,
                       :orientation_y => 2,
                       :orientation_z => 3
      l.orientation.should == [1,2,3]
    end
  end

  describe "#spherical_orientation" do
    it "returns orientating in spherical coordinate system" do
      loc = Location.new :orientation_x => 1,
                         :orientation_y => 0,
                         :orientation_z => 0
      o = loc.spherical_orientation
      o.size.should == 2
      (o[0] - 1.57).should < 0.001
       o[1].should == 0
    end
  end

  describe "#orientated_towards?" do
    context "location oriented towards coordinate" do
      it "returns true" do
        l = Location.new :coordinates => [0, 0, 0],
                         :orientation => [0.57, 0.57, 0.57]
        l.oriented_towards?(0.57, 0.57, 0.57).should be_true
        l.oriented_towards?(1.14, 1.14, 1.14).should be_true
        l.oriented_towards?(0.285, 0.285, 0.285).should be_true
      end
    end

    context "location not orientated towards coordinate" do
      it "returns false" do
        l = Location.new :coordinates => [0, 0, 0],
                         :orientation => [0.57, 0.57, 0.57]

        l.oriented_towards?(0, 0, 0).should be_false
        l.oriented_towards?(1, 0, 0).should be_false
        l.oriented_towards?(-100, 50, 100).should be_false
      end
    end
  end

  describe "#orientation_difference" do
    it "returns sphereical orientation difference" do
      l = Location.new :coordinates => [0, 0, 0],
                       :orientation => [0, 0, 1]
      l.orientation_difference(0, 0, 1).should == [0, 0]
      l.orientation_difference(0, 0, 2).should == [0, 0]

      l.orientation_difference(0, 1, 0).should == [Math::PI/2, Math::PI/2]
      l.orientation_difference(1, 1, 0).should == [Math::PI/2, Math::PI/4]
    end
  end

  describe "#root" do
    context "parent is nil" do
      it 'return self' do
        l = Location.new
        l.root.should == l
      end
    end

    context "parent is not nil" do
      it 'calls root on parent' do
        g = Location.new
        p = Location.new :parent => g
        l = Location.new :parent => p
        p.should_receive(:root).and_call_original
        g.should_receive(:root).and_call_original
        l.root.should == g
      end
    end
  end

  describe "#each_child" do
    before(:each) do
      @g,@p,@l,@s,@c = Array.new(5) { build(:location) }
      @g.add_child @p ; @p.add_child @l ; @p.add_child @s ; @l.add_child @c
    end

    it "calls each_child on each child" do
      invoked = 0
      @g.each_child { |c| invoked += 1 }
      invoked.should == 4
    end

    context "block w/ one parameter passed" do
      it "calls block with each child" do
        children = []
        @g.each_child { |c| children << c }
        children.should == [@p, @l, @c, @s]
      end
    end

    context "block w/ two parameters passed" do
      it "calls block with each parent child" do
        locs = []
        children = []
        @g.each_child { |l,c|
          locs << l
          children << c
        }
        locs.should == [@g, @p, @l, @p]
        children.should == [@p, @l, @c, @s]
      end
    end
  end

  describe "#add_child" do
    context "child already added" do
      it "does not add child" do
        p = build(:location)
        l = build(:location)
        p.add_child l
        p.add_child l
        p.children.size.should == 1
      end
    end

    it "adds child" do
      p = build(:location)
      l = build(:location)
      p.add_child l
      p.children.should == [l]
    end
  end

  describe "#remove_child" do
    context "child not present" do
      it "does nothing" do
        p  = build(:location)
        l1 = build(:location)
        l2 = build(:location)
        p.add_child l1
        p.remove_child l2
        p.children.should == [l1]
      end
    end

    it "removes child" do
    end
  end

  [:total_x, :total_y, :total_z].each { |t|
    describe "##{t}" do
      before(:each) do
        @c = t.to_s.gsub(/total_/, '').intern
      end

      context "parent is nil" do
        it "returns 0" do
          l = Location.new
          l.parent = nil
          l.send(t).should == 0
        end
      end

      context "parent is not nil" do
        it "calls parent #{t}" do
          p = Location.new @c => 0
          l = Location.new @c => 0
          l.parent = p
          p.should_receive(t).and_call_original
          l.send(t)
        end

        it "returns parent.#{t} + [x|y|z]" do
          g = Location.new
          p = Location.new  @c => -20
          l = Location.new  @c =>  10
          p.parent = g ; l.parent = p
          p.send(t).should == -20
          l.send(t).should == -10
        end
      end
    end
  }

  describe "#-" do
    it "return distance between locations" do
      l1 = Location.new :x => 10, :y => 10, :z => 10
      l2 = Location.new :x => -5, :y => -7, :z => 30
      (l1 - l2).should be_within(OmegaTest::CLOSE_ENOUGH).of(30.2324329156619)
    end
  end

  describe "#+" do
    it "returns new location" do
      l1 = Location.new :coordinates => [0, 0, 0]
      l2 = l1 + [10, 10, 10]
      l2.should be_an_instance_of(Location)
      l2.should_not equal(l1)
    end

    it "updates new location from self" do
      l1 = Location.new :parent_id => 50, :coordinates => [0, 0, 0],
                        :movement_strategy => MovementStrategies::Linear.new
      l2 = l1 + [10,10,10]
      l2.parent_id.should == 50
      l2.movement_strategy.should be_an_instance_of(MovementStrategies::Linear)
    end

    it "adds specified values to coordinates" do
      l1 = Motel::Location.new :x => 4, :y => 2, :z => 0
      l2 = l1 + [10, 20, 30]

      l1.x.should == 4
      l1.y.should == 2
      l1.z.should == 0
      l2.x.should == 14
      l2.y.should == 22
      l2.z.should == 30
    end
  end

  describe "#to_json" do
    it "returns location in json format" do
      cb = Callbacks::Movement.new :min_distance => 20
      l = Location.new(:id => 42,
                       :x => 10, :y => -20, :z => 0.5,
                       :orientation => [0, 0, -1],
                       :restrict_view => false, :restrict_modify => true,
                       :parent_id => 15,
                       :movement_strategy =>
                         Motel::MovementStrategies::Linear.new(:speed => 51))
      l.callbacks['movement'] << cb

      j = l.to_json
      j.should include('"json_class":"Motel::Location"')
      j.should include('"id":42')
      j.should include('"x":10')
      j.should include('"y":-20')
      j.should include('"z":0.5')
      j.should include('"orientation_x":0')
      j.should include('"orientation_y":0')
      j.should include('"orientation_z":-1')
      j.should include('"restrict_view":false')
      j.should include('"restrict_modify":true')
      j.should include('"parent_id":15')
      j.should include('"movement_strategy":{')
      j.should include('"json_class":"Motel::MovementStrategies::Linear"')
      j.should include('"speed":51')
      j.should include('"callbacks":{"movement":[{')
      j.should include('"json_class":"Motel::Callbacks::Movement"')
      j.should include('"min_distance":20')
    end
  end

  describe "#json_create" do
    it "returns location from json format" do
      j = '{"json_class":"Motel::Location","data":{"y":-20,"restrict_view":false,"parent_id":15,"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Linear","data":{"direction_vector_x":1,"direction_vector_y":0,"direction_vector_z":0,"step_delay":1,"speed":51}},"z":0.5,"x":10,"orientation_z":0.5,"id":42}}'
      l = JSON.parse(j)

      l.class.should == Motel::Location
      l.id.should == 42
      l.x.should  == 10
      l.y.should  == -20
      l.z.should  == 0.5
      l.orientation_z.should  == 0.5
      l.restrict_view.should be_false
      l.restrict_modify.should be_true
      l.parent_id.should == 15
      l.movement_strategy.class.should == Motel::MovementStrategies::Linear
      l.movement_strategy.speed.should == 51
    end
  end

  describe "#basic" do
    it "returns new minimal location" do
      l = Location.basic(123)
      l.should be_an_instance_of(Location)
      l.should be_valid

      l.id.should == 123
      l.parent.should == nil
      l.parent_id.should == nil
      l.movement_strategy.should == MovementStrategies::Stopped.instance
      l.coordinates.should == [0,0,0]
      l.orientation.should == [0,0,1]
    end
  end

  describe "#random" do
    it "returns new random location" do
      r = Motel::Location.random
      r.should be_an_instance_of(Location)

      # should just be missing an id
      r.should_not be_valid
      r.id = 42
      r.should be_valid
    end

    context "maximum specified" do
      it "constrains coordinates to maximums" do
        l = Location.random :max_x => 10
        l.x.should be <   10
        l.x.should be >= -10

        l = Location.random :max => 10
        l.x.should be <   10
        l.x.should be >= -10
        l.y.should be <   10
        l.y.should be >= -10
        l.z.should be <   10
        l.z.should be >= -10
      end
    end

    context "minimum specified" do
      it "constrains coordinates to minimums" do
        l = Location.random :min_x => 10
        l.x.abs.should be >=  10

        l = Location.random :min => 10
        l.x.abs.should be >=  10
        l.y.abs.should be >=  10
        l.z.abs.should be >=  10
      end
    end
  end

end # describe Location
end # module Motel
