# elliptical movement strategy tests
#
# Copyright (C) 2009-2013 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/location'
require 'motel/movement_strategies/linear'

module Motel::MovementStrategies
describe Elliptical do
  describe "#dmaj" do
    it "returns major axis direction vector" do
      e = Elliptical.new :dmajx => 0, :dmajy => 0, :dmajz => -1
      e.dmaj.should == [0,0,-1]
    end
  end

  describe "#dmin" do
    it "returns minor axis direction vector" do
      e = Elliptical.new :dminx => 0, :dminy => 0, :dminz => -1
      e.dmin.should == [0,0,-1]
    end
  end

  describe "#direction" do
    it "returns direction" do
      e = Elliptical.new :dmajx => 0, :dmajy => 0, :dmajz => -1,
                         :dminx => 0, :dminy => 1, :dminz =>  0
      e.direction.should == [0,0,-1,0,1,0]
    end
  end

  describe "#initialize" do
    it "sets defaults" do
      e = Elliptical.new
      e.direction.should == [1,0,0,0,1,0]
    end

    it "sets attributes" do
      e = Elliptical.new :relative_to => Elliptical::CENTER,
                         :speed => 5,
                         :e => 0.5, :p => 10,
                         :dmajx => 1, :dmajy =>  3, :dmajz => 2,
                         :dminx => 3, :dminy => -1, :dminz => 0

      # the orthogonal direction vectors get normalized
      e.dmajx.should be_within(OmegaTest::CLOSE_ENOUGH).of(0.267261241912424)
      e.dmajy.should be_within(OmegaTest::CLOSE_ENOUGH).of(0.801783725737273)
      e.dmajz.should be_within(OmegaTest::CLOSE_ENOUGH).of(0.534522483824849)
      e.dminx.should be_within(OmegaTest::CLOSE_ENOUGH).of(0.948683298050514)
      e.dminy.should be_within(OmegaTest::CLOSE_ENOUGH).of(-0.316227766016838)
      e.dminz.should == 0

      e.speed.should == 5
      e.relative_to.should == Elliptical::CENTER
      e.e.should == 0.5
      e.p.should == 10
    end

    it "accepts direction" do
      e = Elliptical.new :direction => [[-1,0,0],[0,-1,0]]
      e.direction.should == [-1,0,0,0,-1,0]

      e = Elliptical.new :direction => [-1,0,0,0,-1,0]
      e.direction.should == [-1,0,0,0,-1,0]

      e = Elliptical.new :dmaj => [0,0,-1],
                         :dmin => [0,-1,0]
      e.direction.should == [0,0,-1,0,-1,0]

      e = Elliptical.new :direction => [[-1,0,0],[0,-1,0]],
                         :dmaj => [0,1,0],
                         :dminx => 1,
                         :dminy => 0
      e.direction.should == [0,1,0,1,0,0]
    end

    it "normalizes directions" do
      e = Elliptical.new :direction => [[10,0,0],[0,-5,0]]
      e.direction.should == [1,0,0,0,-1,0]
    end
  end

  describe "#valid?" do
    before(:each) do
      # minimum valid attributes
      @valid = Elliptical.new :relative_to => Elliptical::CENTER,
                              :speed => 5, :p => 100, :e => 0.5
    end

    context "dmaj is not normalized" do
      it "returns false" do
        @valid.dmajx = 10
        @valid.should_not be_valid
      end
    end

    context "dmin is not normalized" do
      it "returns false" do
        @valid.dminy = -20
        @valid.should_not be_valid
      end
    end

    context"axis' are not orthogonal" do
      it "returns false" do
        @valid.dmajx = -1
        @valid.dminx = -1
        @valid.dminy =  0
        @valid.should_not be_valid
      end
    end

    context "eccentricity not valid" do
      it "returns false" do
        @valid.e = 'foobar'
        @valid.should_not be_valid

        @valid.e = 5
        @valid.should_not be_valid
      end
    end

    context "semi latus rectum not valid" do
      it "returns false" do
        @valid.p = 'foobar'
        @valid.should_not be_valid

        @valid.p = -10
        @valid.should_not be_valid
      end
    end

    context "speed not valid" do
      it "returns false" do
        @valid.speed = 'foobar'
        @valid.should_not be_valid

        @valid.speed = -10
        @valid.should_not be_valid
      end
    end

    context "relative to not valid" do
      it "return false" do
        @valid.relative_to = 'fooz'
        @valid.should_not be_valid
      end
    end

    it "returns true" do
      @valid.should be_valid
    end
  end

  describe "#move" do
    context "elliptical is invalid" do
      it "does not move location" do
        elliptical = Elliptical.new
        l = Motel::Location.new

        lambda {
          elliptical.move l, 1
        }.should_not change(l, :coordinates)
      end
    end

    it "moves location along elliptical path by speed * elapsed_time" do
      e = Elliptical.new(:step_delay        => 5,
                         :relative_to       => Elliptical::CENTER,
                         :speed             => 1.57,
                         :e => 0, # circle
                         :p => 1,
                         :direction => [1,0,0,0,1,0])

      x,y,z = 1,0,0
      l = Motel::Location.new(:movement_strategy => e,
                              :x => x, :y => y, :z => z)

      # move and validate
      e.move l, 1
      (0 - l.x).abs.round_to(2).should == 0
      (1 - l.y).abs.round_to(2).should == 0
      (0 - l.z).abs.round_to(2).should == 0

      e.move l, 1
      (-1 - l.x).abs.round_to(2).should == 0
      (0  - l.y).abs.round_to(2).should == 0
      (0  - l.z).abs.round_to(2).should == 0

      e.move l, 1
      (0  - l.x).abs.round_to(2).should == 0
      (-1 - l.y).abs.round_to(2).should == 0
      (0  - l.z).abs.round_to(2).should == 0

      e.move l, 1
      (1  - l.x).abs.round_to(2).should == 0
      (0 - l.y).abs.round_to(2).should == 0
      (0  - l.z).abs.round_to(2).should == 0
    end

    # TODO more elliptical path test cases
  end

  describe "#to_json" do
    it "returns elliptical in json format" do
      m = Elliptical.new :relative_to => Elliptical::CENTER,
                         :step_delay => 21, :speed => 42, :e => 0.5, :p => 420,
                         :direction  => [-1,0,0,0,-1,0]

      j = m.to_json
      j.should include('"json_class":"Motel::MovementStrategies::Elliptical"')
      j.should include('"step_delay":21')
      j.should include('"speed":42')
      j.should include('"relative_to":"center"')
      j.should include('"e":0.5')
      j.should include('"p":420')
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

  describe "#random" do
    it "returns new random elliptical strategy" do
      m = Elliptical.random
      m.should be_an_instance_of(Elliptical)
      Elliptical.random.should_not eq(m)
    end

    context "dimensions specified" do
      it "restrict axis to specified number of dimensions" do
        m = Elliptical.random :dimensions => 2
        m.dmajz.should == 0
        m.dminz.should == 0
      end
    end

    context "relative to" do
      it "sets relative to on location" do
        m = Elliptical.random :relative_to => Elliptical::FOCI
        m.relative_to.should == Elliptical::FOCI
      end
    end

    context "min_e/min_l/min_s specified" do
      it "constrains e/l/s to minimums" do
        m = Elliptical.random :min_e => 0.3,
                              :min_p => 90,
                              :min_s => 10
        m.e.should >= 0.3
        m.p.should >= 90
        m.speed.should >= 10
      end
    end

    context "max_e/max_l/max_s specified" do
      it "constrains e/l/s to maximums" do
        m = Elliptical.random :max_e => 0.7,
                              :max_p => 120,
                              :max_s => 20
        m.e.should < 0.7
        m.p.should < 120
        m.speed.should < 20
      end
    end
  end

  # TODO test other orbital methods

end # describe Elliptical
end # module Motel::MovementStrategies
