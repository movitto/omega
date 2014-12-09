# Omega Common Specs
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/constraints'

describe Object do
  describe "#numeric?" do
    context "instance of numeric" do
      it "returns true" do
        1.should be_numeric
        1.1.should be_numeric
      end
    end

    context "not an instance of numeric" do
      it "returns false" do
        '1'.should_not be_numeric
        :a.should_not be_numeric
        nil.should_not be_numeric
        [].should_not be_numeric
        {}.should_not be_numeric
      end
    end
  end

  describe "#numeric_string?" do
    context "not a string" do
      it "returns false" do
        1.numeric_string?.should be_false
        nil.numeric_string?.should be_false
      end
    end

    context "string does not parse into float" do
      it "returns false" do
        "a".numeric_string?.should be_false
      end
    end

    context "string parses into float" do
      it "returns true" do
        "1".numeric_string?.should be_true
        "1.1".numeric_string?.should be_true
      end
    end
  end

  describe "#attr_from_args" do
    let(:obj) { Object.new }

    context "args has key in params" do
      it "invokes setter with arg value" do
        obj.should_receive(:property=).with('value')
        obj.attr_from_args({:property => 'value'},
                           {:property => 'default'})
      end
    end

    context "args has string key in params" do
      it "invokes setter with arg value" do
        obj.should_receive(:property=).with('value')
        obj.attr_from_args({'property' => 'value'},
                           {:property  => 'default'})
      end
    end

    context "args does not have key" do
      it "invokes getter and uses value to invoke setter" do
        obj.should_receive(:property).and_return('set')
        obj.should_receive(:property=).with('set')
        obj.attr_from_args({}, :property => 'default')
      end

      context "getter value is nil" do
        it "invokes setter with default from param" do
          obj.should_receive(:property).and_return(nil)
          obj.should_receive(:property=).with('default')
          obj.attr_from_args({}, :property => 'default')
        end
      end
    end
  end

  describe "#update_from" do
    let(:obj) { Object.new }
    let(:old) { Object.new }

    it "looks up specified attributes in old and sets in local obj" do
      oldh = {:attr1 => 'val1', :attr2 => 'val2', :attr3 => 'val3'}
      obj.should_receive(:attr1=).with('val1')
      obj.should_receive(:attr2=).with('val2')
      obj.should_not_receive(:attr3=).with('val2')

      obj.update_from oldh, :attr1, :attr2
    end

    it "retrieves specified attributes in old and sets in local obj" do
      old.should_receive(:attr1).and_return('val1')
      old.should_receive(:attr2).and_return('val2')
      obj.should_receive(:attr1=).with('val1')
      obj.should_receive(:attr2=).with('val2')
      obj.update_from old, :attr1, 'attr2'
    end

    context ":skip_nil is false" do
      it "copies nil values" do
        old.should_receive(:attr1).and_return(nil)
        obj.should_receive(:attr1=).with(nil)
        obj.update_from old, :attr1, :skip_nil => false
      end
    end

    context ":skip_nil is true" do
      it "does not copy nil values" do
        old.should_receive(:attr1).and_return(nil)
        obj.should_not_receive(:attr1=)
        obj.update_from old, :attr1, :skip_nil => true
      end
    end

    context ":skip_nil is not set" do
      it "does not copy nil values" do
        old.should_receive(:attr1).and_return(nil)
        obj.should_not_receive(:attr1=)
        obj.update_from old, :attr1
      end
    end
  end
end

describe Array do
  describe "#uniq_by" do
  end
end

describe String do
  describe "#demodulize" do
    it "extracts module portion of string and returns remaining" do
      "Motel::MovementStrategies::Stopped".demodulize.should == "Stopped"
    end
  end

  describe "#modulize" do
    it "extracts modules portion of string and returns it" do
      "Motel::MovementStrategies::Linear".modulize.should == "Motel::MovementStrategies"
    end
  end

  describe "#constantize" do
    it "returns nested constant" do
      "Motel::MovementStrategies::Stopped".constantize.should == Motel::MovementStrategies::Stopped
    end
  end
end

describe Module do
  describe "#subclasses" do
  end

  describe "#module_classes" do
  end

  describe "#foreign_reference" do
  end

  describe "#parent_name" do
  end

  describe "#parent" do
  end
end
