# manufactured::transfer_resource tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/loot'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#collect_loot", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Manufactured::RJR, :LOOT_METHODS
      @registry = Manufactured::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)

      # add users, motel, and cosmos modules, initialze manu module
      @n.dispatcher.add_module('users/rjr/init')
      @n.dispatcher.add_module('motel/rjr/init')
      @n.dispatcher.add_module('cosmos/rjr/init')
      dispatch_manufactured_rjr_init(@n.dispatcher)

      @sys = create(:solar_system)
      @sh  = create(:valid_ship, :solar_system => @sys)
      @rsh = @registry.safe_exec { |es| es.find &with_id(@sh.id) }
      @lt  = create(:valid_loot, :solar_system => @sys)
      @rlt = @registry.safe_exec { |es| es.find &with_id(@lt.id) }

      @rs  = build(:resource)
      @rlt.resources << @rs
    end

    context "invalid ship id/type" do
      it "raises DataNotFound" do
        lambda {
          @s.collect_loot 'invalid', @lt.id
        }.should raise_error(DataNotFound)

        st = create(:valid_station)
        lambda {
          @s.collect_loot st.id, @lt.id
        }.should raise_error(DataNotFound)
      end
    end

    context "invalid loot id/type" do
      it "raises DataNotFound" do
        lambda {
          @s.collect_loot @sh.id, 'invalid'
        }.should raise_error(DataNotFound)

        st = create(:valid_station)
        lambda {
          @s.collect_loot @sh.id, st.id
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient permissions (modify-ship)" do
      it "raise PermissionError" do
        lambda {
          @s.collect_loot @sh.id, @lt.id
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient permissions (modify-ship)" do
      before(:each) do
        add_privilege @login_role, 'modify', 'manufactured_entities'
      end

      it "does not raise PermissionError" do
        lambda {
          @s.collect_loot @sh.id, @lt.id
        }.should_not raise_error()
      end

      it "updates ship location" do
        @s.node.should_receive(:invoke).
           with('motel::get_location', 'with_id', @sh.location.id).
           and_call_original
        @s.node.should_receive(:invoke).and_call_original
        @s.collect_loot @sh.id, @lt.id
      end

      it "transfers all resources in loot" do
        @s.collect_loot @sh.id, @lt.id
        sri = @rsh.resources.collect { |r| r.id }
        sri.should include(@rs.id)

        lri = @rlt.resources.collect { |r| r.id }
        lri.should_not include(@rs.id)
      end

      context "error during resource transfer" do
        it "ensures resource allocation is reset to pre-transfer state" do
          @rsh.should_receive(:add_resource).and_call_original
          @rlt.should_receive(:remove_resource).and_raise(Exception)
          @rsh.should_receive(:remove_resource).and_call_original

          @s.collect_loot @sh.id, @lt.id
          @rsh.resources.collect { |r| r.id }.should_not include(@rs.id)
        end
      end

      it "raises collected_loot on ship" do
        @rsh.should_receive(:run_callbacks).with(:collected_loot, @rs)
        @s.collect_loot @sh.id, @lt.id
      end

      context "all resources transfered from loot" do
        it "deletes loot" do
          lambda {
            @s.collect_loot @sh.id, @lt.id
          }.should change{@registry.entities.size}.by(-1)
          @registry.entity(&with_id(@lt.id)).should be_nil
        end
      end

      it "updates loot collected user attribute"

      it "returns ship" do
        r = @s.collect_loot @sh.id, @lt.id
        r.should be_an_instance_of(Ship)
        r.id.should == @sh.id
      end
    end

  end # describe #transfer_resource

  describe "#dispatch_manufactured_rjr_loot" do
    it "adds manufactured::collect_loot to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_loot(d)
      d.handlers.keys.should include("manufactured::collect_loot")
    end
  end
end #module Manufactured::RJR
