# Omega Server args DSL tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/dsl/args'

module Omega
module Server
describe DSL do
  include Omega::Server::DSL

  describe "#filter_properites" do
    it "returns new instance of data type" do
      o = Object.new
      filter_properties(o).should_not equal(o)
    end

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

    context "hash source specified" do
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
