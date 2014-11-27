# manufactured::move entity_inbetween_systems helper specs
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/move/entity_between_systems'

module Manufactured::RJR
  describe "#move_entity_between_systems", :rjr => true do
    include Omega::Server::DSL
    include Manufactured::RJR

    before(:each) do
      setup_manufactured :MOVE_METHODS
      @sys  = create(:solar_system)
      @rsys = Cosmos::RJR.registry.safe_exec { |es| es.find &with_id(@sys.id) }

      @sh  = create(:valid_ship,
                    :solar_system => @sys,
                    :location => build(:location,
                                       :coordinates => [10,0,0]))
      @rsh = @registry.safe_exec { |es| es.find &with_id(@sh.id) }

      @nsys = create(:solar_system)
      @rnsys = Cosmos::RJR.registry.safe_exec { |es| es.find &with_id(@nsys.id) }

      @jg   = create(:jump_gate,
                     :solar_system => @sys,
                     :endpoint => @nsys,
                     :trigger_distance => 500,
                     :location => build(:location,
                                        :coordinates => [0,0,0]))
      @rjg  = Cosmos::RJR.registry.safe_exec { |es| es.find &with_id(@jg.id) }

      # XXX update registry ship's system manually (normally done by move_entity)
      @sh.solar_system = @rsys
    end

    context "ship specified" do
      context "ship not within trigger distance of a gate to system" do
        it "raises OperationError" do
          @rjg.location.x = 5000
          lambda {
            move_entity_between_systems(@sh, @nsys)
          }.should raise_error(OperationError)
        end
      end

      context "ship is docked" do
        it "raises OperationError" do
          sh = create(:valid_ship, :docked_at => build(:station))
          lambda {
            move_entity_between_systems(sh, @nsys)
          }.should raise_error(OperationError)
        end
      end
    end

    it "sets entity parent system" do
      move_entity_between_systems(@sh, @nsys)
      @sh.solar_system.should == @nsys
      @sh.location.movement_strategy.should == Motel::MovementStrategies::Stopped.instance
    end

    it "updates motel w/ new entity & removes callbacks" do
      Manufactured::RJR.node.should_receive(:invoke).
                        with("motel::update_location", an_instance_of(Motel::Location))
      Manufactured::RJR.node.should_receive(:invoke).
                        with("motel::remove_callbacks", @sh.location.id, 'movement')
      Manufactured::RJR.node.should_receive(:invoke).
                        with("motel::remove_callbacks", @sh.location.id, 'rotation')
      move_entity_between_systems(@sh, @nsys)
    end

    context "system.proxy_to is set" do
      before(:each) do
        @nsys.proxy_to = 'remote-server'
        @p = Omega::Server::ProxyNode.new :dst => 'jsonrpc://localhost:8888'
        @p.stub(:login).and_return(@p)
        @p.stub(:invoke)
      end

      it "retreives specified proxy" do
        Omega::Server::ProxyNode.should_receive(:with_id).
                                 with('remote-server').and_return(@p)
        move_entity_between_systems(@sh, @nsys)
      end

      it "logs in using proxy" do
        Omega::Server::ProxyNode.should_receive(:with_id).and_return(@p)

        @p.should_receive(:login)
        move_entity_between_systems(@sh, @nsys)
      end

      it "invokes manufactured::create_entity with proxy" do
        Omega::Server::ProxyNode.should_receive(:with_id).and_return(@p)
        @p.should_receive(:invoke).with('manufactured::create_entity', @sh)
        move_entity_between_systems(@sh, @nsys)
      end

      it "deletes entity from registry" do
        Omega::Server::ProxyNode.should_receive(:with_id).and_return(@p)
        registry.should_receive(:delete) # TODO test selector
        move_entity_between_systems(@sh, @nsys)
      end

      it "deletes entity location from motel" do
        Omega::Server::ProxyNode.should_receive(:with_id).and_return(@p)
        Manufactured::RJR.node.should_receive(:invoke).
                          with("motel::delete_location", @sh.location.id)
        Manufactured::RJR.node.should_receive(:invoke).at_least(:once)
        move_entity_between_systems(@sh, @nsys)
      end

      it "removes permissions to entity and location from owner's role" do
        role_id = "user_role_#{@sh.user_id}"
        Omega::Server::ProxyNode.should_receive(:with_id).and_return(@p)
        Manufactured::RJR.node.should_receive(:invoke).
                          with("users::remove_privilege", role_id,
                               'view', "manufactured_entity-#{@sh.id}")
        Manufactured::RJR.node.should_receive(:invoke).
                          with("users::remove_privilege", role_id,
                               'modify', "manufactured_entity-#{@sh.id}")
        Manufactured::RJR.node.should_receive(:invoke).
                          with("users::remove_privilege", role_id,
                               'view', "location-#{@sh.location.id}")
        Manufactured::RJR.node.should_receive(:invoke).at_least(:once)
        move_entity_between_systems(@sh, @nsys)
      end
    end

    context "system.proxy_to is not set" do
      it "updates registry entity" do
        @registry.should_receive(:update).with(@sh, :solar_system).and_call_original
        move_entity_between_systems(@sh, @nsys)
        @rsh.system_id.should == @nsys.id
      end
    end

    it "adds new SystemJump event to registry" do
      lambda{
        move_entity_between_systems(@sh, @nsys)
      }.should change{@registry.entities.length}.by(1)
      event = @registry.entities.last
      event.should be_an_instance_of(Manufactured::Events::SystemJump)
      event.entity.id.should == @sh.id
      event.old_system.id.should == @sys.id
    end
  end # describe #move_entity_between_systems

end
