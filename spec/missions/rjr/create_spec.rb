# missions::create_event, missions::create_mission tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/rjr/create'
require 'rjr/dispatcher'

module Missions::RJR
  describe "#create_event", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Missions::RJR, :CREATE_METHODS
      @registry = Missions::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    context "insufficient privileges (create-mission_events)" do
      it "raises PermissionError" do
        new_event = build(:event)
        lambda {
          @s.create_event(new_event)
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient privileges (create-mission_events)" do
      before(:each) do
        add_privilege(@login_role, 'create', 'mission_events')
      end

      it "does not raise PermissionError" do
        new_event = build(:event)
        lambda {
          @s.create_event(new_event)
        }.should_not raise_error
      end

      context "non-event specified" do
        it "raises ValidationError" do
          lambda {
            @s.create_event(42)
          }.should raise_error(ValidationError)
        end
      end

      it "creates new event in registry" do
        new_event = build(:event)
        lambda {
          @s.create_event(new_event)
        }.should change{@registry.entities.size}.by(1)
        @registry.entity(&with_id(new_event.id)).should_not be_nil
      end

      it "returns event" do
        new_event = build(:event)
        r = @s.create_event(new_event)
        r.should be_an_instance_of(Omega::Server::Event)
        r.id.should == new_event.id
      end
    end

  end # describe "#create_event"

  describe "#create_mission", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Missions::RJR, :CREATE_METHODS
      @registry = Missions::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end


    context "insufficient privileges (create-missions)" do
      it "raises PermissionError" do
        new_mission = build(:mission)
        lambda {
          @s.create_mission(new_mission)
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient privileges (create-missions)" do
      before(:each) do
        add_privilege(@login_role, 'create', 'missions')
      end

      it "does not raise PermissionError" do
        new_mission = build(:mission)
        lambda {
          @s.create_mission(new_mission)
        }.should_not raise_error
      end

      context "non-mission specified" do
        it "raises ValidationError" do
          lambda {
            @s.create_mission(42)
          }.should raise_error(ValidationError)
        end
      end

      context "creator missing" do
        it "sets creator to current user" do
          new_mission = build(:mission, :creator => nil)
          @s.create_mission(new_mission)
          @registry.entity(&with_id(new_mission.id)).creator_id.should == @login_user.id
        end
      end

      it "stores original mission callbacks" do
        mission = build(:mission)
        mission.should_receive :store_callbacks
        @s.create_mission(mission)
      end

      it "resolves mission dsl references" do
        new_mission = build(:mission)
        Missions::DSL::Client::Proxy.should_receive(:resolve).with(:mission => new_mission)
        @s.create_mission(new_mission)
      end

      it "creates new mission in registry" do
        new_mission = build(:mission)
        lambda {
          @s.create_mission(new_mission)
        }.should change{@registry.entities.size}.by(1)
        @registry.entity(&with_id(new_mission.id)).should_not be_nil
      end

      it "returns mission" do
        new_mission = build(:mission)
        r = @s.create_mission(new_mission)
        r.should be_an_instance_of(Mission)
        r.id.should == new_mission.id
      end
    end
  end # describe #create_mission

  describe "#dispatch_missions_rjr_create" do
    it "adds missions::create_event to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_missions_rjr_create(d)
      d.handlers.keys.should include("missions::create_event")
    end

    it "adds missions::create_mission to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_missions_rjr_create(d)
      d.handlers.keys.should include("missions::create_mission")
    end
  end

end #module Missions::RJR
