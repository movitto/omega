# Elliptical Axis Mixin Tests
#
# Copyright (C) 2009-2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'

module Motel::MovementStrategies
describe EllipticalAxis do
  let(:axis) { Object.new.extend(EllipticalAxis) }

  describe "#dmaj" do
    it "returns major axis direction vector" do
      axis.dmajx =  0
      axis.dmajy =  0
      axis.dmajz = -1
      axis.dmaj.should == [0,0,-1]
    end
  end

  describe "#dmin" do
    it "returns minor axis direction vector" do
      axis.dminx =  0
      axis.dminy =  0
      axis.dminz = -1
      axis.dmin.should == [0,0,-1]
    end
  end

  describe "#direction" do
    it "returns direction" do
      axis.dmajx =  0
      axis.dmajy =  0
      axis.dmajz = -1
      axis.dminx =  0
      axis.dminy =  1
      axis.dminz =  0
      axis.direction.should == [0,0,-1,0,1,0]
    end
  end

  describe "#axis_from_args" do
    it "sets axis' from direction arg" do
      axis.axis_from_args :direction => [1, 0, 0, 0, 1, 0]
      axis.dmaj.should == [1, 0, 0]
      axis.dmin.should == [0, 1, 0]

      axis.axis_from_args 'direction' => [-1, 0, 0, 0, -1, 0]
      axis.dmaj.should == [-1, 0, 0]
      axis.dmin.should == [0, -1, 0]
    end

    it "sets major axis from compact arg" do
      axis.axis_from_args :dmaj => [0, 0, 1]
      axis.dmaj.should == [0, 0, 1]

      axis.axis_from_args 'dmaj' => [0, 0, -1]
      axis.dmaj.should == [0, 0, -1]
    end

    it "sets minor axis from compact arg" do
      axis.axis_from_args :dmin => [-1, 0, 0]
      axis.dmin.should == [-1, 0, 0]

      axis.axis_from_args 'dmin' => [1, 0, 0]
      axis.dmin.should == [1, 0, 0]
    end

    it "sets individual major axis components" do
      axis.axis_from_args :dmajx => 1, :dmajy => 0, :dmajz => 0
      axis.dmaj.should == [1, 0, 0]

      axis.axis_from_args 'dmajx' => -1, 'dmajy' => 0, 'dmajz' => 0
      axis.dmaj.should == [-1, 0, 0]
    end

    it "sets individual minor axis components" do
      axis.axis_from_args :dminx => 1, :dminy => 0, :dminz => 0
      axis.dmaj.should == [1, 0, 0]

      axis.axis_from_args 'dminx' => -1, 'dminy' => 0, 'dminz' => 0
      axis.dmin.should == [-1, 0, 0]
    end

    it "normalizes major axis" do
      axis.axis_from_args :dmajx => 10, :dmajy => -20, :dmajz => 30
      axis.dmaj.should == [0.2672612419124244, -0.5345224838248488, 0.8017837257372731]
    end

    it "normalizes minor axis" do
      axis.axis_from_args :dminx => 10, :dminy => 20, :dminz => 30
      axis.dmin.should == [0.2672612419124244, 0.5345224838248488, 0.8017837257372731]
    end

    it "sets defaults" do
      axis.axis_from_args({})
      axis.dmaj.should == [1, 0, 0]
      axis.dmin.should == [0, 1, 0]
    end
  end

  describe "#dmaj_valid?" do
    context "dmaj is not normalized" do
      it "returns false" do
        axis.dmajx = 10
        axis.dmajy = 10
        axis.dmajz = 10
        axis.dmaj_valid?.should be_false
      end
    end

    context "dmaj is normalized" do
      it "returns true" do
        axis.dmajx = 1
        axis.dmajy = 0
        axis.dmajz = 0
        axis.dmaj_valid?.should be_true
      end
    end
  end

  describe "#dmin_valid?" do
    context "dmin is not normalized" do
      it "returns false" do
        axis.dminx = 10
        axis.dminy = 10
        axis.dminz = 10
        axis.dmin_valid?.should be_false
      end
    end

    context "dmin is normalized" do
      it "returns true" do
        axis.dminx = 1
        axis.dminy = 0
        axis.dminz = 0
        axis.dmin_valid?.should be_true
      end
    end
  end

  describe "#axis_orthogonal?" do
    context "major/minor axis' are orthogonal" do
      it "returns true" do
        axis.dmajx = 1
        axis.dmajy = 0
        axis.dmajz = 0
        axis.dminx = 0
        axis.dminy = 1
        axis.dminz = 0
        axis.axis_orthogonal?.should be_true
      end
    end

    context "major/minor axis' are not orthogonal" do
      it "returns false" do
        axis.dmajx = 1
        axis.dmajy = 0
        axis.dmajz = 0
        axis.dminx = 1
        axis.dminy = 0
        axis.dminz = 0
        axis.axis_orthogonal?.should be_false
      end
    end
  end

  describe "#axis_valid?" do
    before(:each) do
      axis.dmajx = 1
      axis.dmajy = 0
      axis.dmajz = 0
      axis.dminx = 0
      axis.dminy = 1
      axis.dminz = 0
    end

    context "dmaj not valid" do
      it "returns false" do
        axis.should_receive(:dmaj_valid?).and_return(false)
        axis.axis_valid?.should be_false
      end
    end

    context "dmin not valid" do
      it "returns false" do
        axis.should_receive(:dmin_valid?).and_return(false)
        axis.axis_valid?.should be_false
      end
    end

    context "axis are not orthogonal" do
      it "returns false" do
        axis.should_receive(:axis_orthogonal?).and_return(false)
        axis.axis_valid?.should be_false
      end
    end

    it "returns true" do
      axis.axis_valid?.should be_true
    end
  end

  describe "#axis_json" do
    it "returns axis json data hash" do
      axis.axis_json.should be_an_instance_of(Hash)
    end

    it "returns major axis components in json data hash" do
      axis.axis_from_args :dmaj => [1, 0, 0]
      axis.dmajx.should == 1
      axis.dmajy.should == 0
      axis.dmajz.should == 0
    end

    it "returns minor axis components in json data hash" do
      axis.axis_from_args :dmin => [0, 1, 0]
      axis.dminx.should == 0
      axis.dminy.should == 1
      axis.dminz.should == 0
    end
  end

  describe "#axis_plane_normal" do
    it "return cross product of major and minor axis'" do
      axis.axis_from_args :direction => [0, 0, 1, 1, 0, 0]
      axis.send(:axis_plane_normal).should == [0, 1, 0]
    end
  end

  describe "#axis_plane_rotation" do
    it "returns axis angle between cartesian normal and axis_plane_normal" do
      axis.axis_from_args :direction => [0, 0, 1, 1, 0, 0]
      axis.send(:axis_plane_rotation).should == [1.5707963267948966, -1.0, 0.0, 0.0]
    end
  end

  describe "#axis_rotation" do
    it "returns axis angle between rotated major cartesian and dmajor" do
      axis.axis_from_args :direction => [0, 0, 1, 1, 0, 0]
      axis.send(:axis_rotation).should == [1.5707963267948966, 0.0, -1.0, 0.0]
    end
  end
end # describe EllipticalAxis
end # module Motel::MovementStrategies
