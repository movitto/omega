# common module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'sproc'

describe "SProc" do
  it "should serialize a block to a string" do
    s = SProc.new {
      1 + 2
    }
    s.to_s.should == "proc { (1 + 2) }"
  end

  it "should unserialize a string to a block" do
    s = SProc.new("proc { (1 + 2) }")
    s.call.should == 3
  end

  it "should be convertable to json" do
    s = SProc.new("proc { (1 + 2) }")

    j = s.to_json
    j.should include('"json_class":"SProc"')
    j.should include('"sblock":"proc { (1 + 2) }"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"SProc","data":{"sblock":"proc { (1 + 2) }"}}'
    s = JSON.parse(j)

    s.class.should == SProc
    s.sblock.should == "proc { (1 + 2) }"
    s.call.should == 3
  end

  it "should raise error if block of string not given" do
    lambda{
      SProc.new
    }.should raise_error(RuntimeError)
  end
end
