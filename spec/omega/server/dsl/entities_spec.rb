# Omega Server entities DSL tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/dsl/entities'

module Omega
module Server
describe DSL do
  include Omega::Server::DSL

  describe "#require_state" do
    it "invokes validation with entity" do
      e = Object.new
      v = proc { |e| }
      v.should_receive(:call).with(e).and_return(true)
      require_state e, &v
    end

    context "validation passes" do
      it "does not raise error" do
        e = Object.new
        v = proc { |e| true }
        lambda {
          require_state e, &v
        }.should_not raise_error
      end
    end

    context "validation fails" do
      it "does raises ValidationError" do
        e = Object.new
        v = proc { |e| false }
        lambda {
          require_state e, &v
        }.should raise_error(ValidationError)
      end
    end
  end

  describe "#with" do
    it "matches objects with specified attribute value" do
      a = [[1,2], [3,4], [5], [6,7,8], Object.new]
      r = a.select &with(:size, 2)
      r.should == [[1,2], [3,4]]

      r = a.find &with(:size, 2)
      r.should == [1,2]
    end
  end


  describe "#with_id" do
    it "matches objects with specified id" do
      o1 = OpenStruct.new
      o1.id = 1
      o1a = OpenStruct.new
      o1a.id = 1
      o2 = OpenStruct.new
      o2.id = 2

      a = [o1, o1a, o2, Object.new]
      r = a.select &with_id(1)
      r.should == [o1, o1a]

      r = a.find &with_id(1)
      r.should == o1
    end
  end

  describe "#matching" do
    it "matches objects using specified callback" do
      a = [1,2,3,4]
      r = a.select(&matching { |e| e % 2 == 0})
      r.should == [2,4]

      r = a.find(&matching { |e| e % 2 == 0})
      r.should == 2
    end
  end

  describe "#in_subsystem" do
    it "matches objects _not_ descending from the Omega::Server namespace" do
      n1 = Omega::Server::EventHandler.new
      n2 = Missions::EventHandlers::DSL.new
      y = Users::User.new
      a = [n1,n2,y]
      a.select(&in_subsystem).should == [y]
    end
  end

  describe "#is_cmd" do
    context "entity is a Omega::Server::Command" do
      it "returns true" do
        is_cmd?(Omega::Server::Command.new).should be_true
      end
    end

    context "entity is not a Omega::Server::Command" do
      it "returns false" do
        is_cmd?(Object.new).should be_false
      end
    end
  end
end # describe DSL
end # module Server
end # module Omega
