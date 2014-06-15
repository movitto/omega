# Omega Server args DSL tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/dsl/args'

module Omega
module Server
describe DSL do
  include Omega::Server::DSL

  describe "#filter_properties" do
    context "array specified" do
      it "returns array w/ filtered elements" do
        filter = {}
        items = [1, 2]
        result = [:a, :b]
        should_receive(:filter_properties).with(items, filter).and_call_original
        should_receive(:filter_properties).with(1, filter).and_return(:a)
        should_receive(:filter_properties).with(2, filter).and_return(:b)
        filter_properties(items, filter).should == result
      end
    end

    context "hash specified" do
      it "returns filtered hash" do
        filter = {}
        hash = {1 => 2}
        result = {:a => :b}
        should_receive(:filter_hash_properties).with(hash, filter).and_return(result)
        filter_properties(hash, filter).should == result
      end
    end

    context "obj specified" do
      it "returns filtered object" do
        filter = {}
        obj = Object.new
        result = Object.new
        should_receive(:filter_obj_properties).with(obj, filter).and_return(result)
        filter_properties(obj, filter).should == result
      end
    end
  end

  describe "#filter_hash_properites" do
    before(:each) do
      @o = {:first => 123, :second => 123}
    end

    it "creates a new hash" do
      filter_properties(@o).should_not eq(@o)
    end

    it "copies whitelisted attributes to new hash" do
      filter_properties(@o, :allow => :first).should == {:first => 123}
    end

    it "copies whitelisted string attributes to new hash" do
      @o['third'] = 123
      filter_properties(@o, :allow => :third).should == {:third => 123}
    end
  end

  describe "#filter_obj_properites" do
    it "returns new instance of data type" do
      o = Object.new
      filter_properties(o).should_not equal(o)
    end

    context ":allow specified" do
      it "copies whitelisted attributes from original instance to new one" do
        o = OpenStruct.new
        o.first = 123

        n = filter_properties o, :allow => [:first]
        n.first.should == 123
      end

      it "does not copy attributes not on the whitelist" do
        o = OpenStruct.new
        o.first  = 123
        o.second = 234

        n = filter_properties o, :allow => [:first]
        n.first.should == 123
        n.second.should be_nil
      end

      it "copies a single whitelisted attribute from original instance to new one" do
        o = OpenStruct.new
        o.first = 123
        o.second = 234

        n = filter_properties o, :allow => :first
        n.first.should == 123
        n.second.should be_nil
      end
    end

    context ":scope specified" do
      context "object does not specify scope" do
        it "copies all json attributes from original instance to new one" do
          obj = OpenStruct.new
          obj.json_attrs = [:attr1]
          obj.attr1 = :val1

          result = filter_obj_properties(obj, :scope => :anything)
          result.attr1.should == :val1
        end
      end

      it "copies scoped attributes from original instance to new one" do
        obj = OpenStruct.new
        obj.should_receive(:respond_to?)
        obj.should_receive(:respond_to?).with(:scoped_attrs).and_return(true)
        obj.should_receive(:scoped_attrs).with(:scope1).and_return([:attr1])
        obj.attr1 = :val1

        result = filter_obj_properties obj, :scope => :scope1
        result.attr1.should == :val1
      end

      it "filters scoped attributes" do
        attr1 = OpenStruct.new
        attr1.scoped_attrs = [:foo]
        should_receive(:filter_obj_properties).with(attr1, :scope => :scope1).
                                               and_return(:val1)

        obj = OpenStruct.new
        obj.json_attrs = [:attr1]
        obj.attr1 = attr1

        should_receive(:filter_obj_properties).with(obj, :scope => :scope1).
                                               and_call_original
        result = filter_obj_properties obj, :scope => :scope1
        result.attr1.should == :val1
      end
    end
  end

  describe "#filter_from_args" do
    before(:each) do
      @f  = nil
      @f1 = proc { |i| @f = i + 1  }
      @f2 = proc { |i| @f = i + 2 }
    end

    it "generates filter from args list" do
      filters = filters_from_args ['with_f1'],
        :with_f1 => @f1, :with_f2 => @f2

      filters.size.should == 1
      filters.first.call(42)
      @f.should == 43
    end

    context "arg specifies invalid filter id" do
      it "throws a ValidationError" do
        lambda {
          filters = filters_from_args ['with_f3'],
            :with_f1 => @f1, :with_f2 => @f2
        }.should raise_error(Omega::ValidationError)
      end
    end
  end
end # describe DSL
end # module Server
end # module Omega
