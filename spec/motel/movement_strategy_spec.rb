# movement strategy module tests
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Motel::MovementStrategy do

  it "should successfully accept and set movement strategy params" do
     ms = Motel::MovementStrategy.new :step_delay => 10
     ms.step_delay.should == 10
  end

  it "should default to no movement" do
     loc = Motel::Location.new :x => 100, :y => -200, :z => 300
     ms = Motel::MovementStrategy.new
     ms.move loc, 2000
     loc.x.should == 100
     loc.y.should == -200
     loc.z.should == 300
  end

  it "should be convertable to json" do
    m = Motel::MovementStrategy.new :step_delay => 20
    j = m.to_json
    j.should include('"json_class":"Motel::MovementStrategy"')
    j.should include('"data":{"step_delay":20}')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Motel::MovementStrategy","data":{"step_delay":20}}'
    m = JSON.parse(j)

    m.class.should == Motel::MovementStrategy
    m.step_delay.should == 20
  end

end
