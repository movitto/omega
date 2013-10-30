# missions::save_state,missions::restore_state tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/rjr/state'
require 'rjr/dispatcher'

require 'tempfile'

module Missions::RJR
  describe "#save_state", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Missions::RJR, :STATE_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    context "not local node" do
      it "raises PermissionError" do
        @n.node_type = 'local-test'
        lambda {
          @s.save_state "anything"
        }.should raise_error(PermissionError)
      end
    end

    it "opens file specified by parameter" do
      t = Tempfile.new 'missions'
      File.should_receive(:open).with(t.path, 'a+').and_call_original
      @s.save_state t.path
    end

    it "disaptches to registry to save state" do
      t = Tempfile.new 'missions'
      Missions::RJR.registry.should_receive(:save)
      @s.save_state t.path
    end

  end # describe #save_state

  describe "#restore_state", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Missions::RJR, :STATE_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    context "not local node" do
      it "raises PermissionError" do
        @n.node_type = 'local-test'
        lambda {
          @s.restore_state 'anything'
        }.should raise_error(PermissionError)
      end
    end

    it "opens file specified by parameter" do
      t = Tempfile.new 'missions'
      File.should_receive(:open).with(t.path, 'r').and_call_original
      @s.restore_state t.path
    end

    it "disaptches to registry to save state" do
      t = Tempfile.new 'missions'
      Missions::RJR.registry.should_receive(:restore)
      @s.restore_state t.path
    end

  end # describe #restore_state

  describe "#dispatch_missions_rjr_state" do
    it "adds missions::save_state to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_missions_rjr_state(d)
      d.handlers.keys.should include("missions::save_state")
    end

    it "adds missions::restore_state to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_missions_rjr_state(d)
      d.handlers.keys.should include("missions::restore_state")
    end
  end

end #module Missions::RJR
