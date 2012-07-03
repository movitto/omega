# moon module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Cosmos::Moon do

  it "should successfully accept and set moon params" do
     planet = Cosmos::Planet.new
     moon   = Cosmos::Moon.new :name => 'moon1', :planet => planet
     moon.name.should == 'moon1'
     moon.location.should_not be_nil
     moon.location.x.should == 0
     moon.location.y.should == 0
     moon.location.z.should == 0
     moon.planet.should == planet
     moon.has_children?.should be_false
     moon.parent.should == moon.planet
  end

  it "should verify validity of moon" do
     moon   = Cosmos::Moon.new :name => 'moon1'
     moon.valid?.should be_true

     moon.name = 11111
     moon.valid?.should be_false

     moon.name = nil
     moon.valid?.should be_false
     moon.name = 'moon1'

     moon.location = nil
     moon.valid?.should be_false
  end

  it "should be not able to be remotely trackable" do
    Cosmos::Moon.remotely_trackable?.should be_false
  end

  it "should be convertable to json" do
    g = Cosmos::Moon.new(:name => 'moon1',
                         :location => Motel::Location.new(:x => 50))

    j = g.to_json
    j.should include('"json_class":"Cosmos::Moon"')
    j.should include('"name":"moon1"')
    j.should include('"json_class":"Motel::Location"')
    j.should include('"x":50')
  end

  it "should be convertable from json" do
    j = '{"data":{"name":"moon1","location":{"data":{"parent_id":null,"z":null,"restrict_view":true,"x":50,"restrict_modify":true,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"id":null,"remote_queue":null,"y":null},"json_class":"Motel::Location"}},"json_class":"Cosmos::Moon"}'
    g = JSON.parse(j)

    g.class.should == Cosmos::Moon
    g.name.should == 'moon1'
    g.location.x.should  == 50
  end

end
