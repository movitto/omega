# Location InHeirarchy Mixin Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'

module Motel
describe Location do
  describe "#parent_id=" do
    it "should set parent_id" do
      l = Location.new
      l.parent_id = 10
      l.parent_id.should == 10
    end

    context "changing parent id" do
      it "should nullify parent" do
        p = Location.new :id => 5
        l = Location.new :parent => p
        l.parent_id = 10
        l.parent.should be_nil
      end
    end
  end

  describe "#parent=" do
    before(:each) do
      @p = build(:location)
      @l = build(:location)
    end

    it "should set parent" do
      @l.parent = @p
      @l.parent.should == @p
    end

    it "should set parent id" do
      @l.parent = @p
      @l.parent_id.should == @p.id

      @l.parent = nil
      @l.parent_id.should == nil
    end
  end

  describe "#root" do
    context "parent is nil" do
      it 'return self' do
        l = Location.new
        l.root.should == l
      end
    end

    context "parent is not nil" do
      it 'calls root on parent' do
        g = Location.new
        p = Location.new :parent => g
        l = Location.new :parent => p
        p.should_receive(:root).and_call_original
        g.should_receive(:root).and_call_original
        l.root.should == g
      end
    end
  end

  describe "#each_child" do
    before(:each) do
      @g,@p,@l,@s,@c = Array.new(5) { build(:location) }
      @g.add_child @p ; @p.add_child @l ; @p.add_child @s ; @l.add_child @c
    end

    it "calls each_child on each child" do
      invoked = 0
      @g.each_child { |c| invoked += 1 }
      invoked.should == 4
    end

    context "block w/ one parameter passed" do
      it "calls block with each child" do
        children = []
        @g.each_child { |c| children << c }
        children.should == [@p, @l, @c, @s]
      end
    end

    context "block w/ two parameters passed" do
      it "calls block with each parent child" do
        locs = []
        children = []
        @g.each_child { |l,c|
          locs << l
          children << c
        }
        locs.should == [@g, @p, @l, @p]
        children.should == [@p, @l, @c, @s]
      end
    end
  end

  describe "#add_child" do
    context "child already added" do
      it "does not add child" do
        p = build(:location)
        l = build(:location)
        p.add_child l
        p.add_child l
        p.children.size.should == 1
      end
    end

    it "adds child" do
      p = build(:location)
      l = build(:location)
      p.add_child l
      p.children.should == [l]
    end
  end

  describe "#remove_child" do
    context "child not present" do
      it "does nothing" do
        p  = build(:location)
        l1 = build(:location)
        l2 = build(:location)
        p.add_child l1
        p.remove_child l2
        p.children.should == [l1]
      end
    end

    it "removes child" do
    end
  end

end # describe Location
end # module Motel
