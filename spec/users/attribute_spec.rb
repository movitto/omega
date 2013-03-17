# attribute module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Users::Attribute do

  it "should properly set attribute defaults" do
    a = Users::Attribute.new
    a.type.should  == nil
    a.level.should == 0
    a.progression.should == 0
  end

  it "should properly initialize attribute" do
    a = Users::Attribute.new :type        => Users::Attributes::NumberOfShips,
                             :level       => 50,
                             :progression => 0.64
    a.type.should  == Users::Attributes::NumberOfShips
    a.level.should == 50
    a.progression.should == 0.64
  end

  it "should initialize type from id" do
    a = Users::Attribute.new :type_id     => Users::Attributes::NumberOfShips.id
    a.type.should  == Users::Attributes::NumberOfShips
  end

  it "should be updatable" do
    a = Users::Attribute.new :level => 0, :progression => 0
    a.update! 0
    a.level.should == 0
    a.progression.should == 0

    a = Users::Attribute.new :level => 0, :progression => 0
    a.update! 1
    a.level.should == 1
    a.progression.should == 0

    a = Users::Attribute.new :level => 0, :progression => 0
    a.update! 0.5
    a.level.should == 0
    a.progression.should == 0.5

    a = Users::Attribute.new :level => 0, :progression => 0
    a.update! -0.5
    a.level.should == 0
    a.progression.should == 0

    a = Users::Attribute.new :level => 0, :progression => 0.5
    a.update! 1
    a.level.should == 1
    a.progression.should == 0.5

    a = Users::Attribute.new :level => 0, :progression => 0.5
    a.update! 2.75
    a.level.should == 3
    a.progression.should == 0.25

    a = Users::Attribute.new :level => 0, :progression => 0.5
    a.update! -0.4
    a.level.should == 0
    (a.progression - 0.1).should < CLOSE_ENOUGH

    a = Users::Attribute.new :level => 0, :progression => 0.5
    a.update! -0.6
    a.level.should == 0
    a.progression.should == 0

    a = Users::Attribute.new :level => 1, :progression => 0
    a.update! 1.1
    a.level.should == 2
    (a.progression - 0.1).should < CLOSE_ENOUGH

    a = Users::Attribute.new :level => 1, :progression => 0
    a.update! -0.25
    a.level.should == 0
    a.progression.should == 0.75

    a = Users::Attribute.new :level => 1, :progression => 0
    a.update! -2
    a.level.should == 0
    a.progression.should == 0
  end

  it "should be convertable to json" do
    a = Users::Attribute.new :type        => Users::Attributes::NumberOfShips,
                             :level       => 50,
                             :progression => 0.64
    j = a.to_json
    j.should include('"json_class":"Users::Attribute"')
    j.should include('"type_id":"'+Users::Attributes::NumberOfShips.id.to_s+'"')
    j.should include('"level":50')
    j.should include('"progression":0.64')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Users::Attribute","data":{"type_id":"number_of_ships","progression":0.64,"level":50}}'
    a = JSON.parse(j)

    a.class.should == Users::Attribute
    a.type.should == Users::Attributes::NumberOfShips
    a.level.should == 50
    a.progression.should == 0.64
  end

end

describe Users::AttributeClass do

  it "should permit subclasses to set/get attributes" do
    TestAttribute.id.should == :test_attribute
    TestAttribute.description.should == 'test attribute description'
    TestAttribute.multiplier.should == 5
  end

  it "should instantiate attribute w/ type of attribute class w/ specified id" do
    a = Users::AttributeClass.create_attribute TestAttribute.id
    a.type.should == TestAttribute
  end

end
