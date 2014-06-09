# manufactured::stop_entity specs
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/stop'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#stop_entity", :rjr => true do
    include Omega::Server::DSL

    before(:each) do
      setup_manufactured :STOP_METHODS

      @sys  = create(:solar_system)
      @rsys = Cosmos::RJR.registry.safe_exec { |es| es.find &with_id(@sys.id) }

      @sh  = create(:valid_ship,
                    :solar_system => @sys,
                    :location => build(:location,
                                       :coordinates => [10,0,0]))
      @rsh = @registry.safe_exec { |es| es.find &with_id(@sh.id) }
      @rshl = Motel::RJR.registry.safe_exec { |es| es.find &with_id(@sh.location.id) }
      @rshl.movement_strategy = Motel::MovementStrategies::Linear.new
    end

    context "invalid entity id specified" do
      it "raises DataNotFound" do
        lambda {
          @s.stop_entity 'invalid'
        }.should raise_error(DataNotFound)
      end
    end

    context "invalid entity class specified" do
      it "raises ArgumentError" do
        lambda {
          @s.stop_entity create(:valid_station).id
        }.should raise_error(ArgumentError)
      end
    end

    context "insufficient permissions (modify manufactured_entity)" do
      it "raises PermissionError" do
        lambda {
          @s.stop_entity @sh.id
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient permissions (modify manufactured_entity)" do
      before(:each) do
        add_privilege @login_role, 'modify', 'manufactured_entities'
      end

      it "does not raise PermissionError" do
        lambda {
          @s.stop_entity @sh.id
        }.should_not raise_error
      end

      it "updates entity location" do
        Manufactured::RJR.node.should_receive(:invoke).
                          with("motel::get_location", 'with_id', @sh.id).
                          and_call_original
        Manufactured::RJR.node.should_receive(:invoke).
                    at_least(1).times.and_call_original
        @s.stop_entity @sh.id
      end

      it "sets entity movement strategy to stopped in motel" do
        @rshl.movement_strategy.
          should be_an_instance_of(Motel::MovementStrategies::Linear)
        @s.stop_entity @sh.id
        @rshl.movement_strategy.should == Motel::MovementStrategies::Stopped.instance
      end

      it "returns entity" do
        r = @s.stop_entity @sh.id
        r.should be_an_instance_of Ship
        r.id.should == @sh.id
      end
    end
  end # describe #stop_entity

  describe "#dispatch_manufactured_rjr_stop" do
    it "adds manufactured::stop_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_stop(d)
      d.handlers.keys.should include("manufactured::stop_entity")
    end
  end
end
