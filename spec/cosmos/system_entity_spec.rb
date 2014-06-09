# Cosmos SystemEntity Module Tests
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/system_entity'

module Cosmos
describe SystemEntity do
  before(:each) do
    @e = OmegaTest::CosmosSystemEntity.new
  end

  describe "#init_system_entity" do
    it "sets system entity values" do
      @e.init_system_entity :size => :foo, :type => :bar
      @e.size.should == :foo
      @e.type.should == :bar
    end
  end

  describe "#system_entity_valid?" do
    context "invalid size" do
      it "returns false" do
        @e.should_receive(:size_valid?).and_return(false)
        @e.system_entity_valid?.should be_false
      end
    end

    context "invalid type" do
      it "returns false" do
        @e.should_receive(:size_valid?).and_return(true)
        @e.should_receive(:type_valid?).and_return(false)
        @e.system_entity_valid?.should be_false
      end
    end

    context "valid size and type" do
      it "returns true" do
        @e.should_receive(:size_valid?).and_return(true)
        @e.should_receive(:type_valid?).and_return(true)
        @e.system_entity_valid?.should be_true
      end
    end
  end

  describe "#system_entity_json" do
    it "returns systemenvironment entity json attributes" do
      @e.size = 4
      @e.type = 5
      @e.system_entity_json.should == {:type => 5, :size => 4}
    end
  end
end # describe SystemEntity
end # module Cosmos
