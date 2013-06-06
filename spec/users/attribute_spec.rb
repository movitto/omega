# attribute module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'users/attribute'

module Users
describe Attribute do
  
  describe "#initialize" do
    it "sets default properties" do
      a = Attribute.new
      a.type.should  == nil
      a.level.should == 0
      a.progression.should == 0
    end

    it "sets properties from args" do
      a = Attribute.new :type        => OmegaTest::Attribute,
                        :level       => 50,
                        :progression => 0.64
      a.type.should  == OmegaTest::Attribute
      a.level.should == 50
      a.progression.should == 0.64
    end

    it "sets type from id" do
      a = Attribute.new :type_id => OmegaTest::Attribute.id
      a.type.should  == OmegaTest::Attribute
    end
  end

  describe "#total" do
    it "returns level + progression" do
      a = Attribute.new
      a.total.should == 0

      a = Attribute.new :level => 1
      a.total.should == 1

      a = Attribute.new :progression => 0.75
      a.total.should == 0.75

      a = Attribute.new :level => 2, :progression => 0.25
      a.total.should == 2.25
    end
  end

  describe "#update" do
    it "updates level and progression" do
      a = Attribute.new :level => 0, :progression => 0
      a.update! 0
      a.level.should == 0
      a.progression.should == 0

      a = Attribute.new :level => 0, :progression => 0
      a.update! 1
      a.level.should == 1
      a.progression.should == 0

      a = Attribute.new :level => 0, :progression => 0
      a.update! 0.5
      a.level.should == 0
      a.progression.should == 0.5

      a = Attribute.new :level => 0, :progression => 0
      a.update! -0.5
      a.level.should == 0
      a.progression.should == 0

      a = Attribute.new :level => 0, :progression => 0.5
      a.update! 1
      a.level.should == 1
      a.progression.should == 0.5

      a = Attribute.new :level => 0, :progression => 0.5
      a.update! 2.75
      a.level.should == 3
      a.progression.should == 0.25

      a = Attribute.new :level => 0, :progression => 0.5
      a.update! -0.4
      a.level.should == 0
      a.progression.should be_within(OmegaTest::CLOSE_ENOUGH).of(0.1)

      a = Attribute.new :level => 0, :progression => 0.5
      a.update! -0.6
      a.level.should == 0
      a.progression.should == 0

      a = Attribute.new :level => 1, :progression => 0
      a.update! 1.1
      a.level.should == 2
      a.progression.should be_within(OmegaTest::CLOSE_ENOUGH).of(0.1)

      a = Attribute.new :level => 1, :progression => 0
      a.update! -0.25
      a.level.should == 0
      a.progression.should == 0.75

      a = Attribute.new :level => 1, :progression => 0
      a.update! -2
      a.level.should == 0
      a.progression.should == 0
    end

    it "invokes callbacks on update" do
      # TODO verify attribute gets passed to test attribute callbacks

      OmegaTest::Attribute.reset_callbacks
      a = Attribute.new :level => 0, :progression => 0, :type => OmegaTest::Attribute
      a.update! 1
       OmegaTest::Attribute.level_up.should be_true
       OmegaTest::Attribute.progression.should be_true
       OmegaTest::Attribute.level_down.should be_false
       OmegaTest::Attribute.regression.should be_false

      OmegaTest::Attribute.reset_callbacks
      a = Attribute.new :level => 0, :progression => 0, :type => OmegaTest::Attribute
      a.update! 0.25
       OmegaTest::Attribute.level_up.should be_false
       OmegaTest::Attribute.progression.should be_true
       OmegaTest::Attribute.level_down.should be_false
       OmegaTest::Attribute.regression.should be_false

      OmegaTest::Attribute.reset_callbacks
      a = Attribute.new :level => 1, :progression => 0, :type => OmegaTest::Attribute
      a.update! -0.25
       OmegaTest::Attribute.level_up.should be_false
       OmegaTest::Attribute.progression.should be_false
       OmegaTest::Attribute.level_down.should be_true
       OmegaTest::Attribute.regression.should be_true

      OmegaTest::Attribute.reset_callbacks
      a = Attribute.new :level => 0, :progression => 0.75, :type => OmegaTest::Attribute
      a.update! -0.25
       OmegaTest::Attribute.level_up.should be_false
       OmegaTest::Attribute.progression.should be_false
       OmegaTest::Attribute.level_down.should be_false
       OmegaTest::Attribute.regression.should be_true

      OmegaTest::Attribute.reset_callbacks
      a = Attribute.new :level => 0, :progression => 0, :type => OmegaTest::Attribute
      a.update! -0.25
       OmegaTest::Attribute.level_up.should be_false
       OmegaTest::Attribute.progression.should be_false
       OmegaTest::Attribute.level_down.should be_false
       OmegaTest::Attribute.regression.should be_false
    end
  end

  describe "#to_json" do
    it "returns user in json format" do
      a = Attribute.new :type        => OmegaTest::Attribute,
                        :level       => 50,
                        :progression => 0.64
      j = a.to_json
      j.should include('"json_class":"Users::Attribute"')
      j.should include('"type_id":"'+OmegaTest::Attribute.id.to_s+'"')
      j.should include('"level":50')
      j.should include('"progression":0.64')
    end
  end

  describe "#json_create" do
    it "returns user from json format" do
      j = '{"json_class":"Users::Attribute","data":{"type_id":"test_attribute","progression":0.64,"level":50}}'
      a = JSON.parse(j)

      a.class.should == Attribute
      a.type.should == OmegaTest::Attribute
      a.level.should == 50
      a.progression.should == 0.64
    end
  end

end # describe Attribute

describe AttributeClass do

  describe "#id" do
    it "sets class id" do
      OmegaTest::Attribute.id.should == :test_attribute
    end
  end

  describe "#description" do
    it "sets class description" do
      OmegaTest::Attribute.description.should == 'test attribute description'
    end
  end

  describe "#multiplier" do
    it "sets class multiplier" do
      OmegaTest::Attribute.multiplier.should == 5
    end
  end

  describe "#callbacks" do
    it "sets class callbacks" do
      OmegaTest::Attribute.callbacks.size.should == 4
      OmegaTest::Attribute.callbacks.keys.should include(:level_up)
      OmegaTest::Attribute.callbacks.keys.should include(:level_down)
      OmegaTest::Attribute.callbacks.keys.should include(:progression)
      OmegaTest::Attribute.callbacks.keys.should include(:regression)
      OmegaTest::Attribute.callbacks[:level_up].size.should == 1
      OmegaTest::Attribute.callbacks[:level_down].size.should == 1
      OmegaTest::Attribute.callbacks[:progression].size.should == 1
      OmegaTest::Attribute.callbacks[:regression].size.should == 1
    end
  end

  describe "#create_attribute" do
    it "creates new instance of attribute class" do
      a = OmegaTest::Attribute.create_attribute
      a.type.should == OmegaTest::Attribute
    end

    it "passes args to attribute intializer" do
      a = OmegaTest::Attribute.create_attribute :level => 10
      a.level.should == 10
    end
  end

  describe "#invoke_callbacks" do
    it "should call registered callbacks" do
      OmegaTest::Attribute.reset_callbacks
      OmegaTest::Attribute.invoke_callbacks(:level_up, :attr)
      OmegaTest::Attribute.level_up.should be_true
      OmegaTest::Attribute.progression.should be_false
      OmegaTest::Attribute.level_down.should be_false
      OmegaTest::Attribute.regression.should be_false
    end
  end

end # describe AttributeClass
end # module Users
