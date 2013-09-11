# missions::assign_mission tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/rjr/assign'
require 'rjr/dispatcher'

module Missions::RJR
  describe "#assign_mission" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Missions::RJR, :ASSIGN_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)

      dispatch_missions_rjr_init(@n.dispatcher)
    end

    context "invalid mission id" do
      it "raises ArgumentError" do
        lambda {
          @s.assign_mission :invalid, create(:user).id
        }.should raise_error(ArgumentError)
      end
    end

    context "invalid user id" do
      it "raises ArgumentError" do
        lambda {
          @s.assign_mission create(:mission).id, :invalid
        }.should raise_error(ArgumentError)
      end
    end

    context "insufficient privileges (modify-users)" do
      it "raises PermissionError" do
        lambda {
          @s.assign_mission create(:mission).id, create(:user).id
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient privileges (modify-users)" do
      before(:each) do
        add_privilege @login_role, 'modify', 'users'
      end

      context "user has active assigned mission" do
        it "raises OperationError" do
          u = create(:user)
          m = create(:mission, :assigned_to => u, :assigned_time => Time.now, :timeout => 5000)
          lambda {
            @s.assign_mission create(:mission).id, u.id
          }.should raise_error(OperationError)
        end
      end

      context "mission not assignable to user" do
        it "raises OperationError" do
          u1 = create(:user)
          u2 = create(:user)
          m = create(:mission, :assigned_to => u2, :assigned_time => Time.now, :timeout => 5000)
          lambda {
            @s.assign_mission m.id, u1.id
          }.should raise_error(OperationError)
        end
      end

      it "assigns mission to user" do
        m = create(:mission)
        u = create(:user)
        @s.assign_mission m.id, u.id
        Missions::RJR.registry.entity(&with_id(m.id)).should be_assigned_to(u.id)
      end

      it "runs mission assignment callbacks" do
        u = create(:user)
        m = create(:mission, :id => 'mission1')
        r = Missions::RJR.registry.safe_exec{ |es| es.find &with_id(m.id) }
        r.assignment_callbacks << proc { 1 }
        r.assignment_callbacks.first.should_receive(:call).
                                     with { |m|
                                       m.id.should == 'mission1'
                                       m.should be_assigned_to(u.id)
                                     }
        @s.assign_mission m.id, u.id
      end

      context "error during a mission assignmnent callback" do
        it "catches error and continues" do
          u = create(:user)
          m = create(:mission, :id => 'mission1')
          r = Missions::RJR.registry.safe_exec{ |es| es.find &with_id(m.id) }
          r.assignment_callbacks << proc { raise "Err" }
          r.assignment_callbacks << proc { true }
          r.assignment_callbacks.last.should_receive(:call)
          @s.assign_mission m.id, u.id
        end

        it "logs error"
      end

      it "grants view mission to assigned user" do
        u = create(:user)
        m = create(:mission, :id => 'mission1')
        @s.node.should_receive(:invoke).
                with("users::add_privilege",
                     "user_role_#{u.id}",
                     "view", 'mission-' + m.id).and_call_original
        @s.node.should_receive(:invoke).at_least(1).times.and_call_original
        @s.assign_mission m.id, u.id
        Users::RJR.registry.entity{ |e| e.id == u.id }.
                            has_privilege_on?('view', 'mission-' + m.id).should be_true
      end

      it "returns mission" do
        m = create(:mission)
        r = @s.assign_mission(m.id, create(:user).id)
        r.should be_an_instance_of(Mission)
        r.id.should == m.id
      end
    end
  end

  describe "#dispatch_missions_rjr_assign" do
    it "adds missions::assign_mission to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_missions_rjr_assign(d)
      d.handlers.keys.should include("missions::assign_mission")
    end
  end
end #module Users::RJR
