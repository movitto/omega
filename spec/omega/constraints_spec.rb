# Omega Constraints Spec
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/constraints'

module Omega
describe Constraints do
  describe "#get" do
    it "retrieves target from constriants json" do
      Constraints.should_receive(:data).and_return({'a' => {'b' => 1}})
      Constraints.get('a', 'b').should == 1
    end
  end

  describe "#deviation" do
    it "retrieves targetDeviation from constraints json" do
      Constraints.should_receive(:data).and_return({'a' => {'bDeviation' => 1}})
      Constraints.deviation('a', 'b').should == 1
    end
  end

  describe "#randomize" do
    it "generates random value between base target and +/- deviation" do
      r1 = Constraints.randomize(5, 3)
      r2 = Constraints.randomize(5, 3)
      r1.should_not == r2
      r1.should < 8
      r2.should < 8
      r1.should >= 2
      r2.should >= 2
    end

    context "constraint is a coordinate object" do
      it "generates random coordates between base target and +/ deviation" do
        base = {'x' => 10, 'y' => 20, 'z' => 30}
        dev  = {'x' =>  5, 'y' => 10, 'z' =>  5}
        r1 = Constraints.randomize(base, dev)
        r2 = Constraints.randomize(base, dev)
        r1.should_not == r2
        r1['x'].should <  15
        r1['x'].should >=  5
        r2['x'].should <  15
        r2['x'].should >=  5
        r1['y'].should <  30
        r1['y'].should >= 10
        r2['y'].should <  30
        r2['y'].should >= 10
        r1['z'].should <  35
        r1['z'].should >= 25
        r2['z'].should <  35
        r2['z'].should >= 25
      end
    end
  end

  describe "#rand_invert" do
    it "randomly inverts value" do
      [1, -1].should include(Constraints.rand_invert(1))
    end

    context "contstraint is a coordiante object" do
      it "randomly inverts indiviual coordinates" do
        c = {'x' => 10, 'y' => 20, 'z' => -30}
        r = Constraints.rand_invert(c)
        [10, -10].should include(c['x'])
        [20, -20].should include(c['y'])
        [30, -30].should include(c['z'])
      end
    end
  end

  describe "#gen" do
    context "deviation set" do
      it "returns randomize constraint" do
        Constraints.should_receive(:get).with('a').and_return(42)
        Constraints.should_receive(:deviation).with('a').and_return(24)
        Constraints.should_receive(:randomize).with(42, 24).and_return(25)
        Constraints.gen('a').should == 25
      end
    end

    context "deviation not set" do
      it "returns target constraint" do
        Constraints.should_receive(:get).with('a').and_return(42)
        Constraints.should_receive(:deviation).with('a').and_return(nil)
        Constraints.gen('a').should == 42
      end
    end
  end

  describe "#max" do
    it "returns upper acceptable deviation boundry for target constraint" do
      data = {'a' => 5, 'aDeviation' => 3}
      Constraints.should_receive(:data).twice.and_return(data)
      Constraints.max('a').should == 8
    end
  end

  describe "#min" do
    it "returns lower acceptable deviation boundry for target constraint" do
      data = {'a' => 5, 'aDeviation' => 3}
      Constraints.should_receive(:data).twice.and_return(data)
      Constraints.min('a').should == 2
    end
  end

  describe "#valid?" do
    context "value is between min/max target bounds" do
      it "return true" do
        Constraints.should_receive(:max).with('a').and_return(10)
        Constraints.should_receive(:min).with('a').and_return(5)
        Constraints.valid?(7, 'a').should be_true
      end
    end

    context "value exceeds min/max target bounds" do
      it "return false" do
        Constraints.should_receive(:max).with('a').twice.and_return(10)
        Constraints.should_receive(:min).with('a').twice.and_return(5)
        Constraints.valid?(17, 'a').should be_false
        Constraints.valid?(2, 'a').should be_false
      end
    end

    context "constraint is a coordiate object" do
      context "all coordinates are between min/max target bounds" do
        it "returns true" do
          max = { 'x' => 20, 'y' => 20, 'z' => 20}
          min = { 'x' => 10, 'y' => 10, 'z' => 10}
          Constraints.should_receive(:max).with('a').and_return(max)
          Constraints.should_receive(:min).with('a').and_return(min)
          Constraints.valid?({'x' => 15, 'y' => 15, 'z' => 15}, 'a').should be_true
        end
      end

      context "at least one coordinate exceeds min/max target bounds" do
        it "returns false" do
          max = { 'x' => 20, 'y' => 20, 'z' => 20}
          min = { 'x' => 10, 'y' => 10, 'z' => 10}
          Constraints.should_receive(:max).with('a').twice.and_return(max)
          Constraints.should_receive(:min).with('a').twice.and_return(min)
          Constraints.valid?({'x' => 5,  'y' => 15, 'z' => 15}, 'a').should be_false
          Constraints.valid?({'x' => 15, 'y' => 25, 'z' => 15}, 'a').should be_false
        end
      end
    end
  end
end # describe Constraints
end # module Omega
