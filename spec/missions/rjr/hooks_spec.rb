# missions::add_hook tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/rjr/hooks'
require 'rjr/dispatcher'

module Missions::RJR
  describe "#add_hook", :rjr => true do
    before(:each) do
      dispatch_to @s, Missions::RJR, :HOOKS_METHODS
      @registry = Missions::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    context "insufficient permissions (create-missions_hooks)" do
      it "raises PermissionError" do
        lambda {
          @s.add_hook Missions::EventHandlers::DSL.new
        }.should raise_error(PermissionError)
      end
    end

    context "handler is not instance of Missions::EventHandlers::DSL" do
      it "raises Validation Error" do
        add_privilege @login_role, 'create', 'missions_hooks'
        lambda {
          @s.add_hook 42
        }.should raise_error(ValidationError)
      end
    end

    it "resolves dsl references in handler" do
      add_privilege @login_role, 'create', 'missions_hooks'
      handler = Missions::EventHandlers::DSL.new
      Missions::DSL::Client::Proxy.should_receive(:resolve).with(:event_handler => handler)
      @s.add_hook(handler)
    end

    it "adds handler to registry" do
      add_privilege @login_role, 'create', 'missions_hooks'
      lambda {
        @s.add_hook(Missions::EventHandlers::DSL.new(:event_id => 'event1')).should be_nil
      }.should change{@registry.entities.size}.by(1)
      @registry.entities.last.event_id.should == 'event1'
    end

    it "returns nil" do
      add_privilege @login_role, 'create', 'missions_hooks'
      @s.add_hook(Missions::EventHandlers::DSL.new).should be_nil
    end
  end

  describe "#dispatch_missions_rjr_hooks" do
    it "adds missions::add_hook to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_missions_rjr_hooks(d)
      d.handlers.keys.should include("missions::add_hook")
    end
  end
end
