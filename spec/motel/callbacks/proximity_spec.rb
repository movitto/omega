# Proximity Callback tests
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'
require 'motel/callbacks/proximity'

module Motel::Callbacks
describe Proximity do
  describe "should_invoke?" do
    context "event is proximity" do
      context "coordinates are not same" do
        it "returns false" do
          l1 = Motel::Location.new :x => 0, :y => 0, :z => 0
          l2 = Motel::Location.new :x => 10, :y => 0, :z => 0
          p = Motel::Callbacks::Proximity.new :to_location => l1
          p.should_invoke?(l2).should be_false


        end
      end

      context "coordinates are same" do
        it "returns true" do
          l1 = Motel::Location.new :x => 0, :y => 0, :z => 0
          l2 = Motel::Location.new :x => 0, :y => 0, :z => 0
          p = Motel::Callbacks::Proximity.new :to_location => l1
          p.should_invoke?(l2).should be_true
        end
      end

      context "max distance set" do
        context "coordinates within distance of each other" do
          it "returns true" do
            l1 = Motel::Location.new :x => 0, :y => 1.5, :z => 0.75
            l2 = Motel::Location.new :x => 2.5, :y => 2.5, :z => 0
            p = Proximity.new :to_location => l2, :max_distance => 10 
            p.should_invoke?(l1).should be_true
          end
        end

        context "coordinates not within distance of each other" do
          it "returns false" do
            l1 = Motel::Location.new :x => 0, :y => 0, :z => 0
            l2 = Motel::Location.new :x => 20, :y => 0, :z => 0
            p  = Proximity.new :to_location => l2,
                               :max_distance => 10
            p.should_invoke?(l1).should be_false
          end
        end
      end

      context "max axis distance set" do
        context "coordinates within distance of each other" do
          it "returns true" do
            l1 = Motel::Location.new :x => 0, :y => 0, :z => 0
            l2 = Motel::Location.new :x => 0, :y => 0, :z => 7
            p  = Proximity.new :max_z => 10, :to_location => l1
            p.should_invoke?(l2).should be_true
          end
        end

        context "coordinates not within distance of each other" do
          it "returns false" do
            l1 = Motel::Location.new :x => 0, :y => 0, :z => 0
            l2 = Motel::Location.new :x => 0, :y => 0, :z => 20
            p  = Proximity.new :max_z => 10, :to_location => l1
            p.should_invoke?(l2).should be_false
          end
        end
      end
    end

    context "event is entered_proximity" do
      context "coordinates are not within proximity" do
        it "returns false" do
          l1 = Motel::Location.new :x => 0, :y => 0, :z => 0
          l2 = Motel::Location.new :x => 20, :y => 0, :z => 0
          p  = Proximity.new :to_location => l2,
                             :max_distance => 10,
                             :event => :entered_proximity
          p.should_invoke?(l1).should be_false
        end
      end

      context "coordiantes were and still are within proximity" do
        it 'returns false' do
          l1 = Motel::Location.new :x => 0, :y => 1.5, :z => 0.75
          l2 = Motel::Location.new :x => 2.5, :y => 2.5, :z => 0
          p  = Proximity.new :to_location => l2,
                             :max_distance => 10,
                             :event => :entered_proximity
          p.instance_variable_set(:@locations_in_proximity, true)
          p.should_invoke?(l1).should be_false
        end
      end

      context "coordinates were not but now are withing proximity" do
        it "returns true" do
          l1 = Motel::Location.new :x => 0, :y => 1.5, :z => 0.75
          l2 = Motel::Location.new :x => 2.5, :y => 2.5, :z => 0
          p  = Proximity.new :to_location => l2,
                             :max_distance => 10,
                             :event => :entered_proximity
          p.instance_variable_set(:@locations_in_proximity, false)
          p.should_invoke?(l1).should be_true
        end
      end
    end

    context "event is left_proximity" do
      context "coordinates are within proximity" do
        it "returns false" do
          l1 = Motel::Location.new :x => 0, :y => 1.5, :z => 0.75
          l2 = Motel::Location.new :x => 2.5, :y => 2.5, :z => 0
          p  = Proximity.new :to_location => l2,
                             :max_distance => 10,
                             :event => :left_proximity
          p.should_invoke?(l1).should be_false
        end
      end

      context "coordinates were not and still are not within proximity" do
        it "returns false" do
          l1 = Motel::Location.new :x => 0, :y => 0, :z => 0
          l2 = Motel::Location.new :x => 20, :y => 0, :z => 0
          p  = Proximity.new :to_location => l2,
                             :max_distance => 10,
                             :event => :left_proximity
          p.instance_variable_set(:@locations_in_proximity, false)
          p.should_invoke?(l1).should be_false
        end
      end

      context "coordinates were but are no longer in proximity" do
        it 'returns true' do
          l1 = Motel::Location.new :x => 0, :y => 0, :z => 0
          l2 = Motel::Location.new :x => 20, :y => 0, :z => 0
          p  = Proximity.new :to_location => l2,
                             :max_distance => 10,
                             :event => :left_proximity
          p.instance_variable_set(:@locations_in_proximity, true)
          p.should_invoke?(l1).should be_true
        end
      end
    end
  end

  describe "#invoke" do
    it "invokes handler with location,to_location" do
      l1 = Motel::Location.new :x => 0, :y => 0, :z => 0
      l2 = Motel::Location.new :x => 0, :y => 0, :z => 0
      cb = proc {}
      p = Proximity.new :to_location => l2, :handler => cb
      cb.should_receive(:call).with(l1, l2)
      p.invoke(l1)
    end

    it "set locations_in_proximity flag" do
      l1 = Motel::Location.new :x => 0, :y => 0, :z => 0
      l2 = Motel::Location.new :x => 0, :y => 0, :z => 0
      p = Proximity.new :to_location => l2, :handler => proc {}
      p.should_receive(:currently_in_proximity).with(l1).and_return(true)
      p.invoke(l1)
      p.instance_variable_get(:@locations_in_proximity).should be_true
    end
  end

  describe "#to_json" do
    it "returns callback in json format" do
      cb = Proximity.new :endpoint_id => 'baz',
                         :max_distance => 10,
                         :max_x        => 5,
                         :event        => 'entered_proximity'

      j = cb.to_json
      j.should include('"json_class":"Motel::Callbacks::Proximity"')
      j.should include('"endpoint_id":"baz"')
      j.should include('"max_distance":10')
      j.should include('"max_x":5')
      j.should include('"max_y":0')
      j.should include('"max_z":0')
      j.should include('"event":"entered_proximity"')
    end
  end

  describe "#json_create" do
    it "returns callback from json format" do
      j = '{"json_class":"Motel::Callbacks::Proximity","data":{"endpoint_id":"baz","max_distance":10,"max_x":5,"max_y":0,"max_z":0,"event":"entered_proximity"}}'
      cb = RJR.parse_json(j)

      cb.class.should == Motel::Callbacks::Proximity
      cb.endpoint_id.should == "baz"
      cb.max_distance.should == 10
      cb.max_x.should == 5
      cb.max_y.should == 0
      cb.max_z.should == 0
      cb.event.should == :entered_proximity
    end
  end
end # describe Proximity
end # describe Motel::MovementStrategies
