# Elliptical Generators Mixin Tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'

module Motel::MovementStrategies
describe EllipticalGenerators do
  let(:elliptical) { Elliptical.new }

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
end # described Generators
end # module Motel::MovementStrategies
