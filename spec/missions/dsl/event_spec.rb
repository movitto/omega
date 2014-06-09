# Missions DSL Event Module tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/dsl/event'

module Missions
module DSL
  describe Event do
    before(:each) do
      @node = Missions::RJR::node.as_null_object
      @m    = build(:mission)
    end

    describe "#resource_collected" do
      before(:each) do
        @sh = build(:ship)
        @rs = build(:resource)
        @evnt = Missions::Events::Manufactured.new 'resource_collected', @sh, @rs, 50
      end

      it "generates a proc" do
        Event.resource_collected.should be_an_instance_of(Proc)
      end

      it "adds collected resource to mission data" do
        Query.should_receive(:check_mining_quantity).twice.and_return(proc{ false })

        Event.resource_collected.call(@m, @evnt)
        @m.mission_data['resources'][@rs.material_id].should == 50

        Event.resource_collected.call(@m, @evnt)
        @m.mission_data['resources'][@rs.material_id].should == 100
      end

      it "invokes Query.check_mining_quantity" do
        cmq = Query.check_mining_quantity
        Query.should_receive(:check_mining_quantity).and_return(cmq)
        cmq.should_receive(:call).with(@m)
        Event.resource_collected.call(@m, @evnt)
      end

      context "check_mining_quantity returns true" do
        it "invokes Event.create_victory_event" do
          Query.should_receive(:check_mining_quantity).and_return(proc { true })
          cve = Event.create_victory_event
          Event.should_receive(:create_victory_event).and_return(cve)
          cve.should_receive(:call).with(@m, @evnt)
          Event.resource_collected.call(@m, @evnt)
        end
      end
    end

    describe "#transferred_out" do
      before(:each) do
        @src  = build(:ship)
        @dst  = build(:ship)
        @rs   = build(:resource)
        @evnt = Missions::Events::Manufactured.new 'transferred_to', @src, @dst, @rs, 50
      end

      it "generates a proc" do
        Event.transferred_out.should be_an_instance_of(Proc)
      end

      it "set last_transfer on mission data" do
        Query.should_receive(:check_transfer).and_return(proc{ false })
        Event.transferred_out.call(@m, @evnt)
        @m.mission_data['last_transfer'].should ==
          { 'dst' => @dst, 'rs' => @rs.material_id, 'q' => @rs.quantity }
      end

      it "invokes Query.check_transfer" do
        ct = Query.check_transfer
        Query.should_receive(:check_transfer).and_return(ct)
        ct.should_receive(:call).with(@m)
        Event.transferred_out.call(@m, @evnt)
      end

      context "check_transfer returns true" do
        it "invokes Event.create_victory_event" do
          Query.should_receive(:check_transfer).and_return(proc { true })
          cve = Event.create_victory_event
          Event.should_receive(:create_victory_event).and_return(cve)
          cve.should_receive(:call).with(@m, @evnt)
          Event.transferred_out.call(@m, @evnt)
        end
      end
    end

    describe "#entity_destroyed" do
      it "generates a proc" do
        Event.entity_destroyed.should be_an_instance_of(Proc)
      end

      it "adds events to mission data" do
        Event.entity_destroyed.call(@m, 42)
        @m.mission_data['destroyed'].should == [42]
      end
    end

    describe "#collected_loot" do
      before(:each) do
        @sh  = build(:ship)
        @rs  = build(:resource)
        @evnt = Missions::Events::Manufactured.new 'collected_loot', @sh, @rs
      end

      it "generates a proc" do
        Event.collected_loot.should be_an_instance_of(Proc)
      end

      it "adds collected loot to mission data" do
        Query.should_receive(:check_loot).and_return(proc{ false })
        Event.collected_loot.call(@m, @evnt)
        @m.mission_data['loot'].should == [@rs]
      end

      it "invokes Query.check_loot" do
        cl = Query.check_loot
        Query.should_receive(:check_loot).and_return(cl)
        cl.should_receive(:call).with(@m)
        Event.collected_loot.call(@m, @evnt)
      end

      context "check_loot return true" do
        it "invokes Event.create_victory_event" do
          Query.should_receive(:check_loot).and_return(proc { true })
          cve = Event.create_victory_event
          Event.should_receive(:create_victory_event).and_return(cve)
          cve.should_receive(:call).with(@m, @evnt)
          Event.collected_loot.call(@m, @evnt)
        end
      end
    end

    describe "#create_victory_event" do
      before(:each) do
        @m.assigned_to = build(:user)
      end

      it "generates a proc" do
        Event.create_victory_event.should be_an_instance_of(Proc)
      end

      it "create new event in local registry" do
        Event.create_victory_event.call(@m, 42)
        evnt = Missions::RJR.registry.entities.first
        evnt.should be_an_instance_of(Missions::Events::Victory)
        evnt.id.should == "mission-#{@m.id}-victory"
        evnt.mission.id.should == @m.id
      end
    end
  end # describe Event
end # module Event
end # module DSL
