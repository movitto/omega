# Motel Core Ext Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Float do
  describe "#round_to" do
    it "returns new float instance rounded to specified percision" do
        5.12345.round_to(1).should == 5.1
        -5.12345.round_to(2).should == -5.12
        5.12345.round_to(6).should == 5.12345
    end

    context "precision < 0" do
      it "raises argument error" do
        lambda {
          5.1.round_to(-1)
        }.should raise_error(ArgumentError)
      end
    end
  end
end

describe Fixnum do
  describe "#round_to" do
    it "returns self" do
      1.round_to(0).should == 1
      2.round_to(1).should == 2
      3.round_to(-1).should == 3
    end
  end

  describe "#zeros" do
    it "returns number of zeros after first non-zero lsb" do
      0.zeros.should == 1

      1.zeros.should == 0
      -1.zeros.should == 0
      10.zeros.should == 1
      -10.zeros.should == 1
      11.zeros.should == 0
      -11.zeros.should == 0
      20.zeros.should == 1
      -20.zeros.should == 1
      100.zeros.should == 2
      -100.zeros.should == 2
      101.zeros.should == 0
      -101.zeros.should == 0
      110.zeros.should == 1
      -110.zeros.should == 1
      111.zeros.should == 0
      -111.zeros.should == 0
      1000.zeros.should == 3
      -1000.zeros.should == 3
      1010.zeros.should == 1
      -1010.zeros.should == 1
      10000.zeros.should == 4
      -10000.zeros.should == 4
      100000.zeros.should == 5
      -100000.zeros.should == 5
    end
  end

  describe "#digits" do
    it "returns number of significant digits" do
      0.digits.should == 0
      1.digits.should == 1
      -1.digits.should == 1
      10.digits.should == 2
      -10.digits.should == 2
      99.digits.should == 2
      100.digits.should == 3
      -100.digits.should == 3
      105.digits.should == 3
      -105.digits.should == 3
      1000.digits.should == 4
      -1000.digits.should == 4
      1010.digits.should == 4
      -1010.digits.should == 4
    end
  end
end
