# Elliptical Path Mixin Tests
#
# Copyright (C) 2009-2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'

module Motel::MovementStrategies
describe EllipticalPath do
  let(:path) { Object.new.extend(EllipticalPath)
                         .extend(EllipticalAxis)}

  describe "#path_from_args" do
    it "initializes e" do
      path.path_from_args :e => 0.1
      path.e.should == 0.1
    end

    it "initializes p" do
      path.path_from_args :p => 100
      path.p.should == 100
    end

    it "initializes relative_to" do
      path.path_from_args :relative_to => Elliptical::FOCI
      path.relative_to.should == Elliptical::FOCI
    end

    it "initializes a" do
      path.path_from_args :a => 100
      path.a.should == 100
    end

    it "initializes b" do
      path.path_from_args :b => 100
      path.b.should == 100
    end

    it "initializes le" do
      path.path_from_args :le => 1000
      path.le.should == 1000
    end

    it "initializes center" do
      args = {:ar => :gs}
      path.should_receive(:center_from_args).with(args)
      path.path_from_args args
    end

    it "initializes focus" do
      args = {:ar => :gs}
      path.should_receive(:focus_from_args).with(args)
      path.path_from_args args
    end

    it "sets defaults" do
      path.path_from_args({})
      path.e.should be_nil
      path.p.should be_nil
      path.relative_to.should == Elliptical::CENTER
      path.a.should be_nil
      path.b.should be_nil
      path.le.should be_nil
    end
  end

  describe "#e_valid?" do
    before(:each) do
      path.e = 0.5
    end

    context "e is not numeric" do
      it "returns false" do
        path.e = :a
        path.e_valid?.should be_false
      end
    end

    context "e < 0" do
      it "returns false" do
        path.e = -0.5
        path.e_valid?.should be_false
      end
    end

    context "e > 1" do
      it "returns false" do
        path.e = 1.1
        path.e_valid?.should be_false
      end
    end

    it "returns true" do
      path.e_valid?.should be_true
    end
  end

  describe "#p_valid?" do
    before(:each) do
      path.p = 100
    end

    context "p is no numeric" do
      it "returns false" do
        path.p = :a
        path.p_valid?.should be_false
      end
    end

    context "p <= 0" do
      it "returns false" do
        path.p = -10
        path.p_valid?.should be_false
      end
    end
  end

  describe "#relative_to_valid?" do
    context "relative_to is center or foci" do
      it "returns true" do
        path.relative_to = Elliptical::CENTER
        path.relative_to_valid?.should be_true

        path.relative_to = Elliptical::FOCI
        path.relative_to_valid?.should be_true
      end
    end

    context "relative_to is not center or foci" do
      it "returns false" do
        path.relative_to = :a
        path.relative_to_valid?.should be_false
      end
    end
  end

  describe "#path_valid?" do
    before(:each) do
      path.e = 0.5
      path.p = 100
      path.relative_to = Elliptical::CENTER
    end

    context "e is not valid" do
      it "returns false" do
        path.should_receive(:e_valid?).and_return(false)
        path.path_valid?.should be_false
      end
    end

    context "p is not valid" do
      it "returns false" do
        path.should_receive(:p_valid?).and_return(false)
        path.path_valid?.should be_false
      end
    end

    context "relative_to is not valid" do
      it "returns false" do
        path.should_receive(:relative_to_valid?).and_return(false)
        path.path_valid?.should be_false
      end
    end

    it "returns true" do
      path.path_valid?.should be_true
    end
  end

  describe "#path_json" do
    it "returns elliptical path json data hash" do
      path.path_json.should be_an_instance_of(Hash)
    end

    it "returns e in elliptical path json" do
      path.e = 0.5
      path.path_json[:e].should == 0.5
    end

    it "returns p in elliptical path json" do
      path.p = 100
      path.path_json[:p].should == 100
    end

    it "returns relative_to in elliptical path json" do
      path.relative_to = Elliptical::FOCI
      path.path_json[:relative_to].should == Elliptical::FOCI
    end

    it "returns a in elliptical path json" do
      path.a = 100
      path.path_json[:a].should == 100
    end

    it "returns b in elliptical path json" do
      path.b = 100
      path.path_json[:b].should == 100
    end

    it "returns le in elliptical path json" do
      path.le = 200
      path.path_json[:le].should == 200
    end

    it "returns center in elliptical path json" do
      path.centerX = -100
      path.centerY = -500
      path.centerZ =  500
      path.path_json[:center].should == [-100, -500, 500]
    end

    it "returns focus in elliptical path json" do
      path.focusX = -100
      path.focusY = -500
      path.focusZ =  500
      path.path_json[:focus].should ==  [-100, -500, 500]
    end
  end

  describe "#intercepts" do
    it "returns a,b" do
      path.a = 100
      path.b = 200
      path.intercepts.should == [100, 200]
    end

    context "p nil and intercepts not set" do
      it "returns nil, nil" do
        path.e = 0.5
        path.intercepts.should == [nil, nil]
      end
    end

    context "e nil and intercepts not set" do
      it "returns nil, nil" do
        path.p = 100
        path.intercepts.should == [nil, nil]
      end
    end

    describe "#a" do
      it "equals p / (1 - e ** 2)" do
        path.e = 0.5
        path.p = 100
        path.intercepts
        path.a.should == 133.33333333333334
      end
    end

    describe "#b" do
      it "equals Math.sqrt(p * a)" do
        path.e = 0.25
        path.p = 200
        path.intercepts
        path.b.should == 206.55911179772892
      end
    end
  end

  describe "#linear_eccentricity" do
    it "equals Math.sqrt(a**2 - b**2)" do
      path.a = 20
      path.b = 10
      path.le.should == 17.320508075688775
    end

    context "intercepts nil and le not set" do
      it "returns nil" do
        path.should_receive(:intercepts).and_return([nil, nil])
        path.le.should be_nil
      end
    end
  end

  describe "#center_from_args" do
    context "relative_to == center" do
      it "sets center to 0" do
        path.relative_to = Elliptical::CENTER
        path.center_from_args :center => [10, 10, 10]
        path.center.should == [0, 0, 0]
      end
    end

    it "sets center from args" do
      path.center_from_args :center => [-20, 100, 10]
      path.center.should == [-20, 100, 10]

      path.center_from_args 'center' => [20, -100, -10]
      path.center.should == [20, -100, -10]
    end
  end

  describe "#center" do
    it "returns center" do
      path.center_from_args :center => [1, 2, -3]
      path.center.should == [1, 2, -3]
    end

    context "dmaj not valid and center not set" do
      it "returns nil, nil, nil" do
        path.should_receive(:dmaj_valid?).and_return(false)
        path.center.should == [nil, nil, nil]
      end
    end

    context "le nil and center not set" do
      it "returns nil, nil, nil" do
        path.should_receive(:linear_eccentricity).and_return(nil)
        path.center.should == [nil, nil, nil]
      end
    end

    context "center is not set" do
      it "sets center to -1 * dmaj * le" do
        path.dmajx = 0.7774815830232241
        path.dmajy = 0.17277368511627203
        path.dmajz = 0.6047078979069521
        path.le    = 1000
        expected = [-1 * path.dmajx * path.le,
                    -1 * path.dmajy * path.le,
                    -1 * path.dmajz * path.le]
        path.center.should == expected
      end
    end
  end

  describe "#center=" do
    it "sets center coordinates" do
      path.center = 100, 200, -300
      path.center.should == [100, 200, -300]
    end
  end

  describe "#focus_from_args" do
    context "relative_to == focus" do
      it "sets focus to 0" do
        path.relative_to = Elliptical::CENTER
        path.focus_from_args :focus => [0, 100, 50]
        path.focus.should == [0, 100, 50]
      end
    end

    it "sets focus from args" do
      path.focus_from_args :focus => [10, -50, 67]
      path.focus.should == [10, -50, 67]
    end
  end

  describe "#focus" do
    it "returns focus" do
      path.focus_from_args :focus => [-20, -10, -15]
      path.focus.should == [-20, -10, -15]
    end

    context "dmaj not valid and center not set" do
      it "returns nil, nil, nil" do
        path.should_receive(:dmaj_valid?).and_return(false)
        path.focus.should == [nil, nil, nil]
      end
    end

    context "le nil and center not set" do
      it "returns nil, nil, nil" do
        path.should_receive(:linear_eccentricity).and_return(nil)
        path.focus.should == [nil, nil, nil]
      end
    end

    context "focus is not set" do
      it "sets focus to dmaj * le" do
        path.dmajx = -0.4923659639173309
        path.dmajy =  0.8616404368553291
        path.dmajz =  0.12309149097933272 
        path.le    = 654
        expected = [-path.dmajx * path.le,
                    -path.dmajy * path.le,
                    -path.dmajz * path.le]
        path.center.should == expected
      end
    end
  end
end # describe ElliptcialPath
end # module Motel::MovementStrategies
