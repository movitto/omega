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
  let(:loc)     { build(:location) }
  let(:other)   { build(:location) }
  let(:linear)  { Motel::MovementStrategies::Linear.new }
  let(:stopped) { Motel::MovementStrategies::Stopped.instance }

  describe "#initialize" do
    it "resets tracked attributes" do
      Location.test_new { |l| l.should_receive(:reset_tracked_attributes) }
    end

    it "initializes base attributes from args" do
      args = {:base => :attrs}
      Location.test_new(args) { |l|
        l.should_receive(:base_attrs_from_args).with(args)
      }
    end

    it "initializes coordinates from args" do
      args = {:coord => :inates}
      Location.test_new(args) { |l|
        l.should_receive(:coordinates_from_args).with(args)
      }
    end

    it "initializes orientation from args" do
      args = {:orient => :ation}
      Location.test_new(args) { |l|
        l.should_receive(:orientation_from_args).with(args)
      }
    end

    it "initializes movement strategy from args" do
      args = {:movement => :strategy}
      Location.test_new(args) { |l|
        l.should_receive(:movement_strategy_from_args).with(args)
      }
    end

    it "initializes callbacks from args" do
      args = {:call => :bacls}
      Location.test_new(args) { |l|
        l.should_receive(:callbacks_from_args).with(args)
      }
    end

    it "initializes heirarchy from args" do
      args = {:heir => :archy}
      Location.test_new(args) { |l|
        l.should_receive(:heirarchy_from_args).with(args)
      }
    end

    it "initializes trackable state from args" do
      args = {:track => :able}
      Location.test_new(args) { |l|
        l.should_receive(:trackable_state_from_args).with(args)
      }
    end

    it "initializes attributes" do
      cbs      = {:movement => []}
      ms       = linear
      nms      = stopped
      parent   = Location.new
      children = [Location.new]
      time     = Time.now

      l = Location.new :id                     =>   'loc1',
                       :restrict_view          =>    false,
                       :restrict_modify        =>    false,
                       :callbacks              =>      cbs,
                       :x                      =>        5,
                       :y                      =>       10,
                       :z                      =>      -20,
                       :movement_strategy      =>       ms,
                       :next_movement_strategy =>      nms,
                       :orx                    =>        0,
                       :ory                    =>        1,
                       :orz                    =>        0,
                       :parent                 =>   parent,
                       :children               => children,
                       :distance_moved         =>      502,
                       :angle_rotated          =>     1.24,
                       :last_moved_at          =>     time

      l.id.should == 'loc1'
      l.restrict_view.should be_false
      l.restrict_modify.should be_false
      l.callbacks.should == cbs
      l.coordinates.should == [5, 10, -20]
      l.movement_strategy.should == ms
      l.next_movement_strategy.should == nms
      l.orientation.should == [0, 1, 0]
      l.parent.should == parent
      l.children.should == children
      l.distance_moved.should == 502
      l.angle_rotated.should == 1.24
      l.last_moved_at.should == time
    end
  end

  describe "#update" do
    it "updates location with updatable_attributes" do
      loc.should_receive(:update_from).with(other, *loc.updatable_attrs)
      loc.update(other)
    end

    it "updates location with specified attributes" do
      loc.should_receive(:update_from).with(other, :id)
      loc.update(other, :id)
    end

    it "copies attributes" do
      other.restrict_view = false
      other.restrict_modify = false
      other.movement_strategy = linear
      other.next_movement_strategy = stopped
      other.orientation = Motel.rand_vector
      other.parent = build(:location)
      other.distance_moved = rand
      other.angle_rotated = rand
      other.last_moved_at = Time.now

      loc.update(other)
      loc.id.should_not == other.id
      loc.restrict_view.should == other.restrict_view
      loc.x.should == other.x
      loc.y.should == other.y
      loc.z.should == other.z
      loc.movement_strategy.should == other.movement_strategy
      loc.next_movement_strategy.should == other.next_movement_strategy
      loc.orx.should == other.orx
      loc.ory.should == other.ory
      loc.orz.should == other.orz
      loc.parent.should == other.parent
      loc.parent_id.should == other.parent_id
      loc.distance_moved.should_not == other.distance_moved
      loc.angle_rotated.should_not == other.angle_rotated
      loc.last_moved_at.should == other.last_moved_at
    end

    it "skips nil attributes" do
      other.x = nil
      orig    = loc.x

      loc.update(other)
      loc.x.should == orig
    end
  end

  describe "#valid" do
    before(:each) do
      loc.id = 'loc1'
      loc.coordinates = 1,2,3
      loc.orientation = 1,0,0
      loc.ms = loc.next_movement_strategy = stopped
    end

    context "id is invalid" do
      it "returns false" do
        loc.should_receive(:id_valid?).and_return(false)
        loc.should_not be_valid
      end
    end

    context "id attributes are invalid" do
      it "returns false" do
        loc.id = nil
        loc.should_not be_valid
      end
    end

    context "coordinates are invalid" do
      it "returns false" do
        loc.should_receive(:coordinates_valid?).and_return(false)
        loc.should_not be_valid
      end
    end

    context "coordinates attributes are invalid" do
      it "returns false" do
        loc.coordinates = ['1', '2', '3']
        loc.should_not be_valid
      end
    end

    context "orientation is invalid" do
      it "returns false" do
        loc.should_receive(:orientation_valid?).and_return(false)
        loc.should_not be_valid
      end
    end

    context "orientation attributes are invalid" do
      it "returns false" do
        loc.orientation = ['1', '0', '0']
        loc.should_not be_valid
      end
    end

    context "movement strategy is invalid" do
      it "returns false" do
        loc.should_receive(:movement_strategy_valid?).and_return(false)
        loc.should_not be_valid
      end
    end

    context "movement strategy attributes are invalid" do
      it "returns false" do
        loc.movement_strategy = :a
        loc.should_not be_valid
      end
    end

    it "returns true" do
      loc.should be_valid
    end
  end

  describe "#to_json" do
    it "returns location in json format" do
      linear.speed = 51
      cb = Callbacks::Movement.new :min_distance => 20
      child1 = build(:location)
      child2 = build(:location)
      l = Location.new(:id                     => 42,
                       :restrict_view          => false,
                       :restrict_modify        => true,
                       :x                      => 10,
                       :y                      => -20,
                       :z                      => 0.5,
                       :orientation            => [0, 0, -1],
                       :distance_moved         => 123,
                       :angle_rotated          => 0.12,
                       :last_moved_at          => Time.now,
                       :parent_id              => 15,
                       :children               => [child1, child2],
                       :movement_strategy      => linear,
                       :next_movement_strategy => stopped)
      l.callbacks['movement'] << cb

      j = l.to_json
      j.should include('"json_class":"Motel::Location"')
      j.should include('"id":42')
      j.should include('"restrict_view":false')
      j.should include('"restrict_modify":true')
      j.should include('"x":10')
      j.should include('"y":-20')
      j.should include('"z":0.5')
      j.should include('"orientation_x":0')
      j.should include('"orientation_y":0')
      j.should include('"orientation_z":-1')
      j.should include('"distance_moved":123')
      j.should include('"angle_rotated":0.12')
      j.should include('"last_moved_at":"'+l.last_moved_str+'"')
      j.should include('"parent_id":15')
      j.should include('"children":[')
      j.should include('"id":'+child1.id.to_s)
      j.should include('"id":'+child2.id.to_s)
      j.should include('"movement_strategy":{')
      j.should include('"json_class":"Motel::MovementStrategies::Linear"')
      j.should include('"speed":51')
      j.should include('"next_movement_strategy":{')
      j.should include('"json_class":"Motel::MovementStrategies::Stopped"')
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

    context "base_attrs_eql? returns false" do
      it "returns false" do
        l1 = Location.new
        l2 = Location.new
        l1.should_receive(:base_attrs_eql?).with(l2).and_return(false)
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

    context "#coordinates_eql? returns false" do
      it "returns false" do
        l1 = Location.new
        l2 = Location.new
        l1.should_receive(:coordinates_eql?).with(l2).and_return(false)
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

    context "#orientation_eql? returns false" do
      it "returns false" do
        l1 = Location.new
        l2 = Location.new
        l1.should_receive(:orientation_eql?).with(l2).and_return(false)
        l1.should_not == l2
      end
    end

    context "movement strategy is different" do
      it "returns false" do
        l1 = Location.new :movement_strategy => linear
        l2 = Location.new
        l1.should_not == l2
      end
    end

    context "#movement_strategy_eql? returns false" do
      it "returns false" do
        l1 = Location.new
        l2 = Location.new
        l1.should_receive(:movement_strategy_eql?).with(l2).and_return(false)
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

    context "#callbacks_eql? returns false" do
      it "returns false" do
        l1 = Location.new
        l2 = Location.new
        l1.should_receive(:callbacks_eql?).with(l2).and_return(false)
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

    context "#heirarchy_eql? returns false" do
      it "returns false" do
        l1 = Location.new
        l2 = Location.new
        l1.should_receive(:heirarchy_eql?).with(l2).and_return(false)
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

        l1 = Location.new :last_moved_at => Time.now
        l2 = Location.new :last_moved_at => Time.now - 20
        l1.should_not == l2
      end
    end

    context "#trackable_state_eql? returns false" do
      it "returns false" do
        l1 = Location.new
        l2 = Location.new
        l1.should_receive(:trackable_state_eql?).with(l2).and_return(false)
        l1.should_not == l2
      end
    end

    it "returns true" do
      Location.new.should == Location.new
    end
  end
end # describe Location
end # module Motel
