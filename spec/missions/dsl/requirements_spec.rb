# Missions DSL Requirements Module tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/dsl/requirements'

module Missions
module DSL
describe Requirements do
  before(:each) do
    @node = Missions::RJR::node.as_null_object
    @m = build(:mission)
    @u = build(:user)
  end

  describe "#shared_station" do
    it "generates a proc" do
      Requirements.shared_station.should be_an_instance_of(Proc)
    end

    it "retrieves ships owned by mission creator and assigning_to user" do
      @node.should_receive(:invoke).
            with('manufactured::get_entities',
                 'of_type', 'Manufactured::Ship',
                 'owned_by', @m.creator.id).and_return([])

      @node.should_receive(:invoke).
            with('manufactured::get_entities',
                 'of_type', 'Manufactured::Ship',
                 'owned_by', @u.id).and_return([])
      Requirements.shared_station.call @m, @u
    end

    context "users have ships with a shared docked station" do
      it "returns true" do
        st = build(:station)
        sh1 = build(:ship, :docked_at => st)
        sh2 = build(:ship, :docked_at => st)
        @node.should_receive(:invoke).once.and_return([sh1])
        @node.should_receive(:invoke).once.and_return([sh2])
        Requirements.shared_station.call(@m, @u).should be_true
      end
    end

    context "users do not have ships with a shared docked station" do
      it "returns false" do
        @node.should_receive(:invoke).once.and_return([])
        @node.should_receive(:invoke).once.and_return([])
        Requirements.shared_station.call(@m, @u).should be_false
      end
    end
  end # dscribe shared_station

  describe "#docked_at" do
    before(:each) do
      @station = build(:station)
    end

    it "generates a proc" do
      Requirements.docked_at(@station).should be_an_instance_of(Proc)
    end

    it "retrieve ships owned by assigning_to user" do
      @node.should_receive(:invoke)
           .with('manufactured::get_entities',
                 'of_type', 'Manufactured::Ship',
                 'owned_by', @u.id).and_return([])
      Requirements.docked_at(@station).call @m, @u
    end

    context "assigning_to user has ship docked at the specified station" do
      it "returns true" do
        @node.should_receive(:invoke).and_return([build(:ship, :docked_at => @station)])
        Requirements.docked_at(@station).call(@m, @u).should be_true
      end
    end

    context "assigning_to user does not have ship docked at the specified station" do
      it "returns false" do
        @node.should_receive(:invoke).and_return([]);
        Requirements.docked_at(@station).call(@m, @u).should be_false
      end
    end
  end # describe docked_at
end # describe Requirements
end # module Requirements
end # module DSL

