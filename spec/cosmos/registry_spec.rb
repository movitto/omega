# registry module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/registry'

require 'stringio'

module Cosmos
describe Registry do
  context "adding entity" do
    it "ensures type is valid" do
      r = Registry.new
      (r << 42).should be_false
      r.entities.should be_empty
    end

    it "ensures entity is valid" do
      g = Entities::Galaxy.new
      r = Registry.new
      (r << g).should be_false
      r.entities.should be_empty
    end

    it "ensure id is unique" do
      g = build(:galaxy)
      r = Registry.new
      (r << g).should be_true
      r.entities.size.should == 1

      (r << g).should be_false
      r.entities.size.should == 1
    end

    it "ensure name is unique" do
      g = build(:galaxy)
      r = Registry.new
      (r << g).should be_true
      r.entities.size.should == 1

      g.id += '-new'
      (r << g).should be_false
      r.entities.size.should == 1
    end

    context "parent is required" do
      it "ensures registry has parent_id" do
        g = build(:galaxy)
        s = build(:solar_system, :parent => g)
        r = Registry.new
        (r << s).should be_false

        (r << g).should be_true
        (r << s).should be_true
      end

      it "sets parent on entity" do
        g = build(:galaxy)
        s = build(:solar_system, :parent => g)
        r = Registry.new
        r << g
        r << s
        r.entities{ |e| e.id == s.id && e.parent.id == g.id }.should_not be_nil
      end

      it "adds child to parent" do
        g = build(:galaxy)
        s = build(:solar_system, :parent => g)
        r = Registry.new
        r << g
        r << s
        r.entities{ |e| e.id == g.id &&
                        e.children.find { |c| c.id == s.id } }.should_not be_nil
      end
    end

    it "adds entity to registry" do
      g = build(:galaxy)
      r = Registry.new
      r.entities.size.should == 0
      (r << g).should be_true
      r.entities.size.should == 1
    end

    it "initializes entity's children" do
      g = build(:galaxy)
      g.add_child build(:solar_system)
      g.children.size.should == 1

      r = Registry.new
      r << g
      r.entities.first.children.should == []
    end
  end

  context "adding jump gate" do
    it "ensures registry has endpoint_id" do
      g = build(:galaxy)
      s1 = build(:solar_system, :parent => g)
      s2 = build(:solar_system, :parent => g)
      j = build(:jump_gate, :solar_system => s1, :endpoint => s2)
      r = Registry.new
      r << g
      r << s1
      (r << j).should be_false

      r << s2
      (r << j).should be_true
    end

    it "sets endpoint on entity" do
      g = build(:galaxy)
      s1 = build(:solar_system, :parent => g)
      s2 = build(:solar_system, :parent => g)
      j = build(:jump_gate)
      r = Registry.new
      r << g
      r << s1
      r << s2
      r << j

      r.entities{ |e| e.id == j.id && e.endpoint.id == s2.id }.should_not be_nil
    end
  end

end # describe Registry
end # module Cosmos
