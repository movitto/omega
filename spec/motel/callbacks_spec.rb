# callbacks module tests
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Motel::Callbacks::Movement do
  it "should invoke handler w/out restriction by default" do
    invoked = false
    loc = Motel::Location.new :x => 0, :y => 0, :z => 0
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
    loc = Motel::Location.new :x => 0, :y => 0, :z => 0
    cb = Motel::Callbacks::Movement.new :min_distance => 10, 
                                           :handler => lambda { |loc, d, dx, dy, dz|
      invoked = true
    }
    cb.invoke(loc, 0, 0, 0)
    invoked.should be_false
    cb.instance_variable_set(:@orig_x, nil) # XXX ugly hack need to reset orig_x so that new 'old coordinates' get accepted

    cb.invoke(loc, -5, 0, 0)
    invoked.should be_false
    cb.instance_variable_set(:@orig_x, nil)

    cb.invoke(loc, 0.5, 1.2, 0.23)
    invoked.should be_false
    cb.instance_variable_set(:@orig_x, nil)

    cb.invoke(loc, 0, 10, 0)
    invoked.should be_true
    invoked = false
    cb.instance_variable_set(:@orig_x, nil)

    cb.invoke(loc, 0, 10, -10)
    invoked.should be_true
    invoked = false
    cb.instance_variable_set(:@orig_x, nil)

    cb.invoke(loc, -10, 0, 0)
    invoked.should be_true
    invoked = false
    cb.instance_variable_set(:@orig_x, nil)

    cb.invoke(loc, 10, 0, 0)
    invoked.should be_true
    invoked = false
    cb.instance_variable_set(:@orig_x, nil)

    loc.x = -5 ; loc.y = 5 ; loc.z = 12
    cb.invoke(loc, 0, 0, 0)
    invoked.should be_true
  end

  it "should invoke handler only when location moves min axis distance" do
    invoked = false
    loc = Motel::Location.new :x => 0, :y => 0, :z => 0
    cb = Motel::Callbacks::Movement.new :min_y => 10, 
                                           :handler => lambda { |loc, d, dx, dy, dz|
      invoked = true
    }
    cb.invoke(loc, 0, 0, 0)
    invoked.should be_false
    cb.instance_variable_set(:@orig_x, nil) # XXX ugly hack need to reset orig_x so that new 'old coordinates' get accepted

    cb.invoke(loc, 0, -6, 0)
    invoked.should be_false
    cb.instance_variable_set(:@orig_x, nil)

    cb.invoke(loc, 10, 0, 0)
    invoked.should be_false
    cb.instance_variable_set(:@orig_x, nil)

    cb.invoke(loc, 10, -5, 20)
    invoked.should be_false
    cb.instance_variable_set(:@orig_x, nil)

    cb.invoke(loc, 0, -10, 0)
    invoked.should be_true
    invoked = false
    cb.instance_variable_set(:@orig_x, nil)

    cb.invoke(loc, 0, 10, 0)
    invoked.should be_true
    invoked = false
  end

  it "should be convertable to json" do
    cb = Motel::Callbacks::Movement.new :endpoint => 'baz',
                                        'min_distance' => 10,
                                        'min_x'        => 5

    j = cb.to_json
    j.should include('"json_class":"Motel::Callbacks::Movement"')
    j.should include('"endpoint":"baz"')
    j.should include('"min_distance":10')
    j.should include('"min_x":5')
    j.should include('"min_y":0')
    j.should include('"min_z":0')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Motel::Callbacks::Movement","data":{"endpoint":"baz","min_distance":10,"min_x":5,"min_y":0,"min_z":0}}'
    cb = JSON.parse(j)

    cb.class.should == Motel::Callbacks::Movement
    cb.endpoint_id.should == "baz"
    cb.min_distance.should == 10
    cb.min_x.should == 5
    cb.min_y.should == 0
    cb.min_z.should == 0
  end

end

describe Motel::Callbacks::Proximity do
  it "should only invoke handler if locations share coordinates by default" do
    invoked = false
    loc1 = Motel::Location.new :x => 0, :y => 0, :z => 0
    loc2 = Motel::Location.new :x => 10, :y => 0, :z => 0

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
    loc1 = Motel::Location.new :x => 0, :y => 0, :z => 0
    loc2 = Motel::Location.new :x => 20, :y => 0, :z => 0
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
    loc1 = Motel::Location.new :x => 0, :y => 0, :z => 0
    loc2 = Motel::Location.new :x => 0, :y => 0, :z => 20
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

  it "should be convertable to json" do
    cb = Motel::Callbacks::Proximity.new :endpoint => 'baz',
                                         'max_distance' => 10,
                                         'max_x'        => 5,
                                         'event'        => 'entered_proximity'

    j = cb.to_json
    j.should include('"json_class":"Motel::Callbacks::Proximity"')
    j.should include('"endpoint":"baz"')
    j.should include('"max_distance":10')
    j.should include('"max_x":5')
    j.should include('"max_y":0')
    j.should include('"max_z":0')
    j.should include('"event":"entered_proximity"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Motel::Callbacks::Proximity","data":{"endpoint":"baz","max_distance":10,"max_x":5,"max_y":0,"max_z":0,"event":"entered_proximity"}}'
    cb = JSON.parse(j)

    cb.class.should == Motel::Callbacks::Proximity
    cb.endpoint_id.should == "baz"
    cb.max_distance.should == 10
    cb.max_x.should == 5
    cb.max_y.should == 0
    cb.max_z.should == 0
    cb.event.should == :entered_proximity
  end
end
