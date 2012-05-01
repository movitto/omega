# star module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Cosmos::Star do

  it "should successfully accept and set star params" do
     star   = Cosmos::Star.new :name => 'star1'
     star.name.should == 'star1'
     star.location.should_not be_nil
     star.location.x.should == 0
     star.location.y.should == 0
     star.location.z.should == 0
     star.solar_system.should be_nil
     star.color.should_not be_nil
     star.size.should_not be_nil
     star.has_children?.should be_false
  end

  it "should be not able to be remotely trackable" do
    Cosmos::Star.remotely_trackable?.should be_false
  end

  it "should be convertable to json" do
    g = Cosmos::Star.new(:name => 'star1',
                         :location => Motel::Location.new(:x => 50))

    j = g.to_json
    j.should include('"json_class":"Cosmos::Star"')
    j.should include('"name":"star1"')
    j.should include('"json_class":"Motel::Location"')
    j.should include('"x":50')
  end

  it "should be convertable from json" do
    j = '{"data":{"color":"FFFF00","size":49,"name":"star1","location":{"data":{"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"z":null,"parent_id":null,"x":50,"restrict_view":true,"id":null,"restrict_modify":true,"y":null},"json_class":"Motel::Location"}},"json_class":"Cosmos::Star"}'
    g = JSON.parse(j)

    g.class.should == Cosmos::Star
    g.name.should == 'star1'
    g.location.x.should  == 50
  end

end
