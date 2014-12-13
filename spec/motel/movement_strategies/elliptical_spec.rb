# Elliptical Movement Strategy Tests
#
# Copyright (C) 2009-2013 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'

module Motel::MovementStrategies
describe Elliptical do
  let(:elliptical) { Elliptical.new   }
  let(:loc)        { build(:location) }

  describe "#initialize" do
    it "initializes axis from args" do
      args = {:ar => :gs}
      Elliptical.test_new(args) { |e| e.should_receive(:axis_from_args).with(args) }
    end

    it "initializes path from args" do
      args = {:ar => :gs}
      Elliptical.test_new(args) { |e| e.should_receive(:path_from_args).with(args) }
    end

    it "initializes movement from args" do
      args = {:ar => :gs}
      Elliptical.test_new(args) { |e| e.should_receive(:movement_from_args).with(args) }
    end

    it "initializes step delay" do
      Elliptical.new(:step_delay => 1).step_delay.should == 1
    end

    it "sets defaults" do
      Elliptical.new.step_delay.should == 0.01
    end
  end

  describe "#valid?" do
    before(:each) do
      elliptical.e = 0.5
      elliptical.p = 100
      elliptical.speed = 5
    end

    context "axis is not valid" do
      it "returns false" do
        elliptical.should_receive(:axis_valid?).and_return(false)
        elliptical.should_not be_valid
      end
    end

    context "path is not valid" do
      it "returns false" do
        elliptical.should_receive(:path_valid?).and_return(false)
        elliptical.should_not be_valid
      end
    end

    context "speed is not valid" do
      it "returns false" do
        elliptical.should_receive(:elliptical_speed_valid?).and_return(false)
        elliptical.should_not be_valid
      end
    end

    it "returns true" do
      elliptical.should be_valid
    end
  end

  describe "#scoped_attrs" do
    it "excludes cached elliptical properties from :create scope" do
      m = Elliptical.new
      m.scoped_attrs(:create).should_not include(:a)
      m.scoped_attrs(:create).should_not include(:b)
      m.scoped_attrs(:create).should_not include(:le)
    end

    it "excludes cached elliptical properties from :get scope" do
      m = Elliptical.new
      m.scoped_attrs(:get).should_not include(:a)
      m.scoped_attrs(:get).should_not include(:b)
      m.scoped_attrs(:get).should_not include(:le)
    end
  end

  describe "#move" do
    before(:each) do
      elliptical.e = 0.9
      elliptical.p = 100000
      elliptical.speed = 50
    end

    context "elliptical is invalid" do
      it "does not move location" do
        elliptical.should_receive(:valid?).and_return(false)
        elliptical.should_not_receive(:move_elliptical)
        elliptical.move(loc, 1)
      end
    end

    it "moves location along elliptical path" do
      elliptical.should_receive(:move_elliptical).with(loc, 1)
      elliptical.move(loc, 1)
    end
  end

  describe "#to_json" do
    it "returns elliptical in json format" do
      m = Elliptical.new :relative_to    => Elliptical::CENTER,
                         :step_delay     => 21,
                         :speed          => 42,
                         :path_tolerance => 10,
                         :e              => 0.5,
                         :p              => 420,
                         :a              => 100,
                         :b              =>  50,
                         :le             => 200,
                         :focus          => [75, -75, 44],
                         :direction      => [-1,0,0,0,-1,0]

      j = m.to_json
      j.should include('"json_class":"Motel::MovementStrategies::Elliptical"')
      j.should include('"relative_to":"center"')
      j.should include('"step_delay":21')
      j.should include('"speed":42')
      j.should include('"path_tolerance":10')
      j.should include('"e":0.5')
      j.should include('"p":420')
      j.should include('"a":100')
      j.should include('"b":50')
      j.should include('"le":200')
      j.should include('"center":[0,0,0]')
      j.should include('"focus":[75,-75,44]')
      j.should include('"dmajx":-1')
      j.should include('"dmajy":0')
      j.should include('"dmajz":0')
      j.should include('"dminx":0')
      j.should include('"dminy":-1')
      j.should include('"dminz":0')
    end
  end

  describe "#json_create" do
    it "returns elliptical from json format" do
      j = '{"data":{"dmajy":0,"speed":42,"dmajz":0,"relative_to":"center","dminx":0,"e":0.5,"dminy":1,"p":420,"step_delay":21,"dminz":0,"dmajx":1},"json_class":"Motel::MovementStrategies::Elliptical"}'
      m = RJR::JSONParser.parse(j)

      m.class.should == Motel::MovementStrategies::Elliptical
      m.step_delay.should == 21
      m.speed.should == 42
      m.relative_to.should == Elliptical::CENTER
      m.e.should == 0.5
      m.p.should == 420
      m.dmajx.should == 1
      m.dmajy.should == 0
      m.dmajz.should == 0
      m.dminx.should == 0
      m.dminy.should == 1
      m.dminz.should == 0
    end
  end
end # describe Elliptical
end # module Motel::MovementStrategies
