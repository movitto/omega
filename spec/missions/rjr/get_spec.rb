# missions::get_missions tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/rjr/get'
require 'rjr/dispatcher'

module Missions::RJR
  describe "#get_missions" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Missions::RJR, :GET_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @s.login @n, @login_user.id, @login_user.password
    end

    it "returns list of all missions" do
      # grant user permissions to view missions
      add_privilege @login_role, 'view', 'missions'

      create(:mission)
      n = Missions::RJR.registry.entities.size
      i = Missions::RJR.registry.entities.collect { |e| e.id }
      s = @s.get_missions
      s.size.should == n
      s.collect { |e| e.id }.should == i
    end

    it "filters missions user does not have permissions to" do
      m = create(:mission)
      @s.get_missions('with_id', m.id).should be_nil
    end

    context "user has permissions to view missions" do
      before(:each) do
        add_privilege @login_role, 'view', 'missions'
      end

      context "mission id specified" do
        it "returns corresponding mission" do
          m = create(:mission)
          m = @s.get_missions 'with_id', m.id
          m.should be_an_instance_of(Mission)
          m.id.should == m.id
        end
      end

      context "assignable_to specified" do
        it "only return entities assignable to user" do
          m1 = create(:mission, :assigned_to => create(:user))
          m2 = create(:mission)
          m = @s.get_missions 'assignable_to', @login_user.id 
          m.size.should == 1
          m.first.id.should == m2.id
        end
      end

      context "assigned_to specified" do
        it "returns entity assigned to user" do
          m = create(:mission, :assigned_to => @login_user)
          r = @s.get_missions 'assigned_to', @login_user.id 
          r.id.should == m.id
        end
      end

      context "is_active specified" do
        it "only returns entities in specified is_active state" do
          m1 = create(:mission, :assigned_to => @login_user,
                                :assigned_time => Time.now,
                                :timeout => 5000)
          m2 = create(:mission)
          m = @s.get_missions 'is_active', true
          m.size.should == 1
          m.first.id.should == m1.id
          m = @s.get_missions 'is_active', false
          m.size.should == 1
          m.first.id.should == m2.id
        end
      end
    end

  end # describe #get_missions

  describe "#dispatch_missions_rjr_get" do
    it "adds missions::get_missions to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_missions_rjr_get(d)
      d.handlers.keys.should include("missions::get_missions")
    end

    it "adds missions::get_mission to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_missions_rjr_get(d)
      d.handlers.keys.should include("missions::get_mission")
    end
  end
end #module Users::RJR
