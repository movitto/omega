# Movement Callback tests
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'
require 'motel/callbacks/movement'

module Motel::Callbacks
describe Movement do
  describe "should_invoke?" do
    it "should return true" do
      m = Movement.new
      m.should_invoke?(build(:location), 0, 0, 0).should be_true
    end

    context "minimum distance set" do
      context "location moved minimum distance" do
        it "should return true" do
          l = Motel::Location.new :x => 0, :y => 0, :z => 0
          m = Movement.new :min_distance => 10
          m.should_invoke?(l, 0, 10, 0).should be_true

          m = Movement.new :min_distance => 10
          m.should_invoke?(l, 0, 10, -10).should be_true

          m = Movement.new :min_distance => 10
          m.should_invoke?(l, -10, 0, 0).should be_true

          m = Movement.new :min_distance => 10
          m.should_invoke?(l, 10, 0, 0).should be_true

          m = Movement.new :min_distance => 10
          l.x = -5 ; l.y = 5 ; l.z = 12
          m.should_invoke?(l, 0, 0, 0).should be_true
        end
      end

      context "location did not move minimum distance" do
        it "should return false" do
          l = Motel::Location.new :x => 0, :y => 0, :z => 0

          m = Movement.new :min_distance => 10
          m.should_invoke?(l, 0, 0, 0).should be_false

          m = Movement.new :min_distance => 10
          m.should_invoke?(l, -5, 0, 0).should be_false

          m = Movement.new :min_distance => 10
          m.should_invoke?(l, 0.5, 1.2, 0.23).should be_false
        end
      end
    end

    context "minimum axis distance set" do
      context "location moved minimum distance along axis" do
        it "should return true" do
          l = Motel::Location.new :x => 0, :y => 0, :z => 0

          m = Movement.new :min_y => 10
          m.should_invoke?(l, 0, 0, 0).should be_false

          m = Movement.new :min_y => 10
          m.should_invoke?(l, 0, -6, 0).should be_false

          m = Movement.new :min_y => 10
          m.should_invoke?(l, 10, 0, 0).should be_false

          m = Movement.new :min_y => 10
          m.should_invoke?(l, 10, -5, 20).should be_false
        end
      end

      context "location did not move minimum distance along axis" do
        it "should return false" do
          l = Motel::Location.new :x => 0, :y => 0, :z => 0

          m = Movement.new :min_y => 10
          m.should_invoke?(l, 0, -10, 0).should be_true

          m = Movement.new :min_y => 10
          m.should_invoke?(l, 0, 10, 0).should be_true
        end
      end
    end
  end

  describe "#invoke" do
    before(:each) do
      @cb = proc {}
      @m = Movement.new :handler => @cb
      @l = Motel::Location.new
    end

    it "invokes handler with distance,dx,dy,dz" do
      @m.should_receive(:get_distance).and_return([1,2,3,4])
      @cb.should_receive(:call).with(@l, 1,2,3,4)
      @m.invoke @l, 1,2,3
    end

    it "resets tracked coordinates" do
      @m.should_receive(:get_distance).and_return([1,2,3,4])
      @m.invoke @l, 1,2,3
      @m.instance_variable_get(:@orig_x).should be_nil
      @m.instance_variable_get(:@orig_y).should be_nil
      @m.instance_variable_get(:@orig_z).should be_nil
    end
  end

  describe "#to_json" do
    it "returns callback in json format" do
      cb = Movement.new :endpoint_id  => 'baz',
                        :min_distance => 10,
                        :min_x        => 5

      j = cb.to_json
      j.should include('"json_class":"Motel::Callbacks::Movement"')
      j.should include('"endpoint_id":"baz"')
      j.should include('"min_distance":10')
      j.should include('"min_x":5')
      j.should include('"min_y":0')
      j.should include('"min_z":0')
    end
  end

  describe "#json_create" do
    it "returns callback from json format" do
      j = '{"json_class":"Motel::Callbacks::Movement","data":{"endpoint_id":"baz","min_distance":10,"min_x":5,"min_y":0,"min_z":0}}'
      cb = RJR::JSONParser.parse(j)

      cb.class.should == Motel::Callbacks::Movement
      cb.endpoint_id.should == "baz"
      cb.min_distance.should == 10
      cb.min_x.should == 5
      cb.min_y.should == 0
      cb.min_z.should == 0
    end
  end

end # describe Movement
end # module Motel::Callbacks
