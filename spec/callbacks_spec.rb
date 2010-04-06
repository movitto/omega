# callbacks module tests
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/spec_helper'

describe Motel::Callbacks::Movement do
  it "should invoke handler w/out restriction by default" do
    invoked = false
    loc = Location.new :x => 0, :y => 0, :z => 0
    Motel::Callbacks::Movement.new(:handler => lambda { |loc, d, dx, dy, dz|
      invoked = true
      loc.should == loc
      d.should == 0
      dx.should == 0
      dy.should == 0
      dz.should == 0
    }).invoke(loc, 0, 0, 0)
    invoked.should be_true
  end

  it "should invoke handler only when location moves min distance" do
    invoked = false
    loc = Location.new :x => 0, :y => 0, :z => 0
    cb = Motel::Callbacks::Movement.new :min_distance => 10, 
                                           :handler => lambda { |loc, d, dx, dy, dz|
      invoked = true
    }
    cb.invoke(loc, 0, 0, 0)
    invoked.should be_false

    cb.invoke(loc, -5, 0, 0)
    invoked.should be_false

    cb.invoke(loc, 0.5, 1.2, 0.23)
    invoked.should be_false

    cb.invoke(loc, 0, 10, 0)
    invoked.should be_true
    invoked = false

    cb.invoke(loc, 0, 10, -10)
    invoked.should be_true
    invoked = false

    cb.invoke(loc, -10, 0, 0)
    invoked.should be_true
    invoked = false

    cb.invoke(loc, 10, 0, 0)
    invoked.should be_true
    invoked = false

    loc.x = -5 ; loc.y = 5 ; loc.z = 12
    cb.invoke(loc, 0, 0, 0)
    invoked.should be_true
  end

  it "should invoke handler only when location moves min axis distance" do
    invoked = false
    loc = Location.new :x => 0, :y => 0, :z => 0
    cb = Motel::Callbacks::Movement.new :min_y => 10, 
                                           :handler => lambda { |loc, d, dx, dy, dz|
      invoked = true
    }
    cb.invoke(loc, 0, 0, 0)
    invoked.should be_false

    cb.invoke(loc, 0, -6, 0)
    invoked.should be_false

    cb.invoke(loc, 10, 0, 0)
    invoked.should be_false

    cb.invoke(loc, 10, -5, 20)
    invoked.should be_false

    cb.invoke(loc, 0, -10, 0)
    invoked.should be_true
    invoked = false

    cb.invoke(loc, 0, 10, 0)
    invoked.should be_true
    invoked = false
  end
end

describe Motel::Callbacks::Proximity do
  it "should only invoke handler if locations share coordinates by default" do
    invoked = false
    loc1 = Location.new :x => 0, :y => 0, :z => 0
    loc2 = Location.new :x => 10, :y => 0, :z => 0

    callback = Motel::Callbacks::Proximity.new :to_location => loc1, :handler => lambda { |loc1, loc2|
      invoked = true
    }
    callback.invoke(loc2)
    invoked.should be_false

    loc2.x = 0
    callback.invoke(loc2)
    invoked.should be_true
  end

  it "should invoke handler only when locations are within max distance of each other" do
    invoked = false
    loc1 = Location.new :x => 0, :y => 0, :z => 0
    loc2 = Location.new :x => 20, :y => 0, :z => 0
    cb = Motel::Callbacks::Proximity.new :to_location => loc2, :max_distance => 10, 
                                           :handler => lambda { |loc1, loc2|
      invoked = true
    }
    cb.invoke(loc1)
    invoked.should be_false

    loc1.y = 1.5
    loc1.z = 0.75
    loc2.x = 2.5
    loc2.y = 2.5
    cb = Motel::Callbacks::Proximity.new :to_location => loc2, :max_distance => 10, 
                                           :handler => lambda { |loc1, loc2|
      invoked = true
    }
    cb.invoke(loc1)
    invoked.should be_true
  end

  it "should invoke handler only when locations are within max axis distance of each other" do
    invoked = false
    loc1 = Location.new :x => 0, :y => 0, :z => 0
    loc2 = Location.new :x => 0, :y => 0, :z => 20
    cb = Motel::Callbacks::Proximity.new :max_z => 10, :to_location => loc1,
                                           :handler => lambda { |loc1, loc2|
      invoked = true
    }
    cb.invoke(loc2)
    invoked.should be_false

    loc2.z = 7
    cb.invoke(loc2)
    invoked.should be_true
  end
end
