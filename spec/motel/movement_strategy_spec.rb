# movement strategy module tests
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'rjr/common'

module Motel
describe MovementStrategy do
  describe "#initialize" do
    it "sets default step delay" do
      m = MovementStrategy.new
      m.step_delay.should == 1
    end

    it "sets attributes" do
      ms = MovementStrategy.new :step_delay => 10
      ms.step_delay.should == 10
    end
  end

  it "should not be valid" do
    MovementStrategy.new.should_not be_valid
  end

  it "should not indicate it should be changed" do
    MovementStrategy.new.change?.should be_false
  end

  describe "#move" do
    it "does nothing" do
      l = Location.new :x => 100, :y => -200, :z => 300
      ms = MovementStrategy.new
      ms.move l, 2000
      l.x.should ==  100
      l.y.should == -200
      l.z.should ==  300
    end
  end

  describe "#to_json" do
    it "returns movement strategy in json format" do
      m = MovementStrategy.new :step_delay => 20
      j = m.to_json
      j.should include('"json_class":"Motel::MovementStrategy"')
      j.should include('"data":{"step_delay":20}')
    end
  end

  describe "#json_create" do
    it "should return movement strategy from json" do
      j = '{"json_class":"Motel::MovementStrategy","data":{"step_delay":20}}'
      m = ::RJR.parse_json(j)

      m.should be_an_instance_of(MovementStrategy)
      m.step_delay.should == 20
    end
  end

end # describe MovementStrategy
end # module Motel
