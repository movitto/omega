# cosmos::save_state,cosmos::restore_state tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO test cosmos::status

require 'spec_helper'
require 'cosmos/rjr/state'
require 'rjr/dispatcher'

require 'tempfile'

module Cosmos::RJR
  describe "#save_state" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Cosmos::RJR, :STATE_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @s.login @n, @login_user.id, @login_user.password
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
      t = Tempfile.new 'cosmos'
      File.should_receive(:open).with(t.path, 'a+').and_call_original
      @s.save_state t.path
    end

    it "disaptches to registry to save state" do
      t = Tempfile.new 'cosmos'
      Cosmos::RJR.registry.should_receive(:save)
      @s.save_state t.path
    end

  end # describe #save_state

  describe "#restore_state" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Cosmos::RJR, :STATE_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @s.login @n, @login_user.id, @login_user.password
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
      t = Tempfile.new 'cosmos'
      File.should_receive(:open).with(t.path, 'r').and_call_original
      @s.restore_state t.path
    end

    it "disaptches to registry to save state" do
      t = Tempfile.new 'cosmos'
      Cosmos::RJR.registry.should_receive(:restore)
      @s.restore_state t.path
    end

  end # describe #restore_state

  describe "#dispatch_cosmos_rjr_state" do
    it "adds cosmos::save_state to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_cosmos_rjr_state(d)
      d.handlers.keys.should include("cosmos::save_state")
    end

    it "adds cosmos::restore_state to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_cosmos_rjr_state(d)
      d.handlers.keys.should include("cosmos::restore_state")
    end
  end

end #module Cosmos::RJR
