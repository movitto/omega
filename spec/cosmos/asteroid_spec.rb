# asteroid module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Cosmos::Asteroid do

  it "should successfully accept and set asteroid params" do
     asteroid   = Cosmos::Asteroid.new :name => 'asteroid1', :color => 'brown', :size => 50
     asteroid.name.should == 'asteroid1'
     asteroid.color.should == 'brown'
     asteroid.size.should == 50
     asteroid.has_children?.should be_false
     asteroid.location.should_not be_nil
     asteroid.location.x.should == 0
     asteroid.location.y.should == 0
     asteroid.location.z.should == 0
     asteroid.solar_system.should be_nil
  end

  it "should verify validity of asteroid" do
     asteroid   = Cosmos::Asteroid.new :name => 'asteroid1'
     asteroid.valid?.should be_true

     asteroid.name = 11111
     asteroid.valid?.should be_false

     asteroid.name = nil
     asteroid.valid?.should be_false
     asteroid.name = 'asteroid1'

     asteroid.location = nil
     asteroid.valid?.should be_false
  end

  it "should be not able to be remotely trackable" do
    Cosmos::Asteroid.remotely_trackable?.should be_false
  end

  it "should be convertable to json" do
    a = Cosmos::Asteroid.new :name => 'asteroid1', :color => 'brown', :size => 50,
                             :location => Motel::Location.new(:x => 50)

    j = a.to_json
    j.should include('"json_class":"Cosmos::Asteroid"')
    j.should include('"name":"asteroid1"')
    j.should include('"color":"brown"')
    j.should include('"size":50')
    j.should include('"json_class":"Motel::Location"')
    j.should include('"x":50')
  end

  it "should be convertable from json" do
    j = '{"data":{"color":"brown","size":50,"name":"asteroid1","location":{"data":{"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"y":null,"z":null,"x":50,"restrict_view":true,"id":null,"restrict_modify":true},"json_class":"Motel::Location"}},"json_class":"Cosmos::Asteroid"}'
    a = JSON.parse(j)

    a.class.should == Cosmos::Asteroid
    a.name.should == 'asteroid1'
    a.color.should == 'brown'
    a.size.should == 50
    a.location.x.should  == 50
  end

end
