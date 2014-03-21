# Missions DSL Resolution Module tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/dsl/resolution'

module Missions
module DSL
  describe Resolution do
    before(:each) do
      @node = Missions::RJR::node.as_null_object
      @m = build(:mission)
    end

    describe "#add_reward" do
      it "generates a proc" do
        Resolution.add_reward(build(:resource)).should be_an_instance_of(Proc)
      end

      it "invokes Query.user_ships" do
        us = Query.user_ships
        Query.should_receive(:user_ships).and_return(us)
        us.should_receive(:call).with(@m).and_return([build(:ship)])
        @node.should_receive(:invoke)
        Resolution.add_reward(build(:resource)).call(@m)
      end

      it "invokes manufactured::add_resource" do
        rs = build(:resource)
        sh = build(:ship)
        Query.should_receive('user_ships').and_return(proc { [sh] })
        @node.should_receive(:invoke).
              with('manufactured::add_resource', sh.id, rs)
        Resolution.add_reward(rs).call(@m)
      end
    end

    describe "#update_user_attributes" do
      before(:each) do
        @u = build(:user)
        @m.assigned_to = @u
      end
      it "generates a proc" do
        Resolution.update_user_attributes.should be_an_instance_of(Proc)
      end

      context "mission is victorious" do
        it "updates MissionsCompleted attribute" do
          @m.victory!
          @node.should_receive(:invoke).
             with('users::update_attribute', @u.id,
                  Users::Attributes::MissionsCompleted.id, 1 )

          Resolution.update_user_attributes.call(@m, @n)
        end
      end
      context "mission failed" do
        it "updates MissionsFailed attribute" do
          @m.failed!
          @node.should_receive(:invoke).
             with('users::update_attribute', @u.id,
                  Users::Attributes::MissionsFailed.id, 1 )

          Resolution.update_user_attributes.call(@m, @n)
        end
      end
    end

    describe "#cleanup_entity_events" do
      before(:each) do
        @sh = build(:ship)
        @m.mission_data[@sh.id] = @sh

        Missions::RJR.registry <<
          Omega::Server::Event.new(:id => "#{@sh.id}_destroyed")

        Missions::RJR.registry <<
          Omega::Server::EventHandler.new(:event_id => "#{@sh.id}_destroyed")
      end

      it "generates a proc" do
        Resolution.cleanup_entity_events(@sh.id, 'destroyed').should be_an_instance_of(Proc)
      end

      it "invokes manufactured::remove_callbacks on each entity" do
        @node.should_receive(:invoke).
              with('manufactured::remove_callbacks', @sh.id)
        Resolution.cleanup_entity_events(@sh.id, 'destroyed').call(@m)
      end

      it "removes each entity/event handler" do
        @node.should_receive(:invoke)
        lambda{
          Resolution.cleanup_entity_events(@sh.id, 'destroyed').call(@m)
        }.should change{Missions::RJR.registry.entities.size}.by(-2)
      end
    end

    describe "#cleanup_expiration_events" do
      before(:each) do
        @eid = "mission-#{@m.id}-expired"
        Missions::RJR.registry << Omega::Server::Event.new(:id => @eid)
      end

      it "removes mission expired event" do
        lambda{
          Resolution.cleanup_expiration_events.call(@m)
        }.should change{Missions::RJR.registry.entities.size}.by(-1)
      end
    end

    describe "#recycle_mission" do
      it "generates a proc" do
        Resolution.recycle_mission.should be_an_instance_of(Proc)
      end

      it "clones mission" do
        @m.should_receive(:clone).and_call_original
        @node.should_receive(:invoke)
        Resolution.recycle_mission.call(@m)
      end

      it "clears new mission assignment" do
        mis = build(:mission)
        @m.should_receive(:clone).and_return(mis)
        mis.should_receive(:clear_assignment!)
        @node.should_receive(:invoke)
        Resolution.recycle_mission.call(@m)
      end

      it "invokes missions::create_mission" do
        mis = build(:mission)
        @m.should_receive(:clone).and_return(mis)
        @node.should_receive(:invoke).
              with('missions::create_mission', mis)
        Resolution.recycle_mission.call(@m)
      end
    end
  end # describe Resolution
end # module DSL
end # module Missions
