# Location Class Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'motel/location'
require 'motel/movement_strategies/linear'
require 'motel/callbacks/movement'
require 'omega/server/callback'
require 'rjr/common'

module Motel
describe Location do
  describe "#initialize" do
    it "sets default tracked attributes" do
      l = Location.new
      l.distance_moved = 50
      l.angle_rotated.should == 0
    end

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

    it "converts string callback keys to symbols" do
      l = Location.new :callbacks => { 'movement' => 42 }
      l.callbacks.should == { :movement => 42 }
    end

    context "invalid string callback key" do
      it "raises ArgumentError" do
        lambda{
          l = Location.new :callbacks => { 'invalid' => 42 }
        }.should raise_error(ArgumentError)
      end

      it "does not create symbol" do
        lambda{
          begin
            l = Location.new :callbacks => { 'new_cb_123' => 42 }
          rescue
          end
        }.should_not change{Symbol.all_symbols.size}
      end
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

  describe "#to_json" do
    it "returns location in json format" do
      cb = Callbacks::Movement.new :min_distance => 20
      l = Location.new(:id => 42,
                       :x => 10, :y => -20, :z => 0.5,
                       :orientation => [0, 0, -1],
                       :restrict_view => false, :restrict_modify => true,
                       :distance_moved => 123, :angle_rotated => 0.12,
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
      j.should include('"distance_moved":123')
      j.should include('"angle_rotated":0.12')
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
      l = ::RJR::JSONParser.parse(j)

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

  describe "clone" do
    it "returns new copy of location" do
      l1 = build(:location)
      l2 = l1.clone
      l1.should == l2
      l1.should_not equal(l2)
    end
  end

  describe "#==" do
    context "other is not a location" do
      it "returns false" do
        Location.new.should_not == 42
      end
    end

    context "base attributes are different" do
      it "returns false" do
        l1 = Location.new :id => 1
        l2 = Location.new :id => 2
        l1.should_not == l2

        l1 = Location.new :restrict_view => true
        l2 = Location.new :restrict_view => false
        l1.should_not == l2

        l1 = Location.new :restrict_modify => true
        l2 = Location.new :restrict_modify => false
        l1.should_not == l2
      end
    end

    context "coordinates are different" do
      it "returns false" do
        l1 = Location.new :x => 1
        l2 = Location.new :x => 2
        l1.should_not == l2

        l1 = Location.new :y => 1
        l2 = Location.new :y => 2
        l1.should_not == l2

        l1 = Location.new :z => 1
        l2 = Location.new :z => 2
        l1.should_not == l2
      end
    end

    context "orientations are different" do
      it "returns false" do
        l1 = Location.new :orx => 1
        l2 = Location.new :orx => 0
        l1.should_not == l2

        l1 = Location.new :ory => 1
        l2 = Location.new :ory => 0
        l1.should_not == l2

        l1 = Location.new :orz => 1
        l2 = Location.new :orz => 0
        l1.should_not == l2
      end
    end

    context "movement strategy is different" do
      it "returns false" do
        l1 = Location.new :movement_strategy => MovementStrategies::Linear.new
        l2 = Location.new
        l1.should_not == l2
      end
    end

    context "callbacks are different" do
      it "returns false" do
        l1 = Location.new :callbacks => {:movement => proc {}}
        l2 = Location.new
        l1.should_not == l2
      end
    end

    context "heirarchy is different" do
      it "returns false" do
        l1 = Location.new :parent_id => 'l4'
        l2 = Location.new :parent_id => 'l5'
        l1.should_not == l2
      end
    end

    context "trackable state is different" do
      it "returns false" do
        l1 = Location.new :distance_moved =>  50
        l2 = Location.new :distance_moved => 150
        l1.should_not == l2

        l1 = Location.new :angle_rotated =>  50
        l2 = Location.new :angle_rotated => 150
        l1.should_not == l2
      end
    end

    it "returns true" do
      Location.new.should == Location.new
    end
  end
end # describe Location
end # module Motel
