# manufactured/rjr/init tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/init'
require 'motel/movement_strategies/linear'
require 'motel/movement_strategies/rotate'

module Manufactured::RJR
  describe "#user" do
    it "provides centralized user" do
      rjr = Object.new.extend(Manufactured::RJR)
      rjr.user.should be_an_instance_of Users::User
      rjr.user.valid_login?(Manufactured::RJR.manufactured_rjr_username,
                             Manufactured::RJR.manufactured_rjr_password)

      rjr.user.should equal(rjr.user)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Manufactured::RJR)
      Manufactured::RJR.user.should equal(rjr.user)
    end
  end

  describe "#node" do
    it "provides centralized rjr node" do
      rjr = Object.new.extend(Manufactured::RJR)
      rjr.node.should be_an_instance_of(::RJR::Nodes::Local)
      rjr.node.should equal(rjr.node)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Manufactured::RJR)
      Manufactured::RJR.node.should equal(rjr.node)
    end
  end

  describe "#user_registry" do
    it "provides access to Users::RJR.registry" do
      rjr = Object.new.extend(Manufactured::RJR)
      rjr.user_registry.should == Manufactured::RJR.user_registry
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Manufactured::RJR)
      Manufactured::RJR.user_registry.should equal(rjr.user_registry)
    end
  end

  describe "#registry" do
    it "provides centralized registry" do
      rjr = Object.new.extend(Manufactured::RJR)
      rjr.registry.should be_an_instance_of(Registry)
      rjr.registry.should equal(rjr.registry)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Manufactured::RJR)
      Manufactured::RJR.registry.should equal(rjr.registry)
    end
  end

  describe "#reset", :rjr => true do
    it "clears manufactured registry" do
      setup_manufactured

      sys = create(:solar_system)
      loc = create(:location, :parent_id => sys.location.id)
      Manufactured::RJR.registry << build(:valid_ship, :location => loc, :solar_system => sys)
      Manufactured::RJR.registry.safe_exec { |entities| entities.size.should > 0 }
      Manufactured::RJR.reset
      Manufactured::RJR.registry.safe_exec { |entities| entities.size.should == 0 }
    end
  end

  describe "#motel_event", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured  :CALLBACK_METHODS

      @sh = create(:valid_ship)
    end

    context "not local node" do
      it "raises PermissionError" do
        @n.node_type = 'local-test'
        lambda {
          @s.motel_event 'anything'
        }.should raise_error(PermissionError)
      end
    end

    context "entity not found" do
      it "does not raise error" do
        lambda {
          @s.motel_event build(:location)
        }.should_not raise_error
      end
    end

    it "updates use DistanceTravelled attribute" do
      enable_attributes {
        ms = Motel::MovementStrategies::Linear.new :speed => 1
        @sh.distance_moved = 500.1
        @sh.location.movement_strategy = ms
        @registry.update @sh, &with_id(@sh.id)

        @s.motel_event @sh.location
        Users::RJR.registry.entity(&with_id(@sh.user_id)).
          attribute(Users::Attributes::DistanceTravelled.id).
          total.should == 500.1
      }
    end

    context "movement strategy different" do
      context "old movement strategy is linear" do
        it "removes motel movement callbacks" do
          lin = Motel::MovementStrategies::Linear.new :speed => 1
          @sh.location.movement_strategy = lin
          @registry.update @sh, &with_id(@sh.id)

          @s.node.should_receive(:invoke).
             with('motel::remove_callbacks', @sh.id, :movement)
          @s.node.should_receive(:invoke)
          @s.motel_event Motel::Location.new :id => @sh.location.id
        end
      end

      context "old movement strategy is rotation" do
        it "removes motel rotation callbacks" do
          rot = Motel::MovementStrategies::Rotate.new
          @sh.location.movement_strategy = rot
          @registry.update @sh, &with_id(@sh.id)

          @s.node.should_receive(:invoke).
             with('motel::remove_callbacks', @sh.id, :rotation)
          @s.motel_event Motel::Location.new :id => @sh.location.id
        end
      end
    end

    it "updates entity with location" do
      loc = build(:location, :id => @sh.location.id)
      @s.motel_event loc
      @registry.entity(&with_id(@sh.id)).location.should == loc
    end

    it "returns nil" do
      @s.motel_event(@sh.location)
    end
  end

  describe "#dispatch_manufactured_rjr_init", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      @d   = @n.dispatcher
      @rjr = Object.new.extend(Manufactured::RJR)
    end

    it "dispatches manufactured* in Manufactured::RJR environment" do
      dispatch_manufactured_rjr_init(@d)
      @d.environments[/manufactured::.*/].should  == Manufactured::RJR
    end

    it "adds manufactured rjr modules to dispatcher" do
      @d.should_receive(:add_module).with('manufactured/rjr/create')
      @d.should_receive(:add_module).with('manufactured/rjr/construct')
      @d.should_receive(:add_module).with('manufactured/rjr/validate')
      @d.should_receive(:add_module).with('manufactured/rjr/get')
      @d.should_receive(:add_module).with('manufactured/rjr/state')
      @d.should_receive(:add_module).with('manufactured/rjr/subscribe_to')
      @d.should_receive(:add_module).with('manufactured/rjr/remove_callbacks')
      @d.should_receive(:add_module).with('manufactured/rjr/resources')
      @d.should_receive(:add_module).with('manufactured/rjr/move')
      @d.should_receive(:add_module).with('manufactured/rjr/follow')
      @d.should_receive(:add_module).with('manufactured/rjr/stop')
      @d.should_receive(:add_module).with('manufactured/rjr/dock')
      @d.should_receive(:add_module).with('manufactured/rjr/mining')
      @d.should_receive(:add_module).with('manufactured/rjr/attack')
      @d.should_receive(:add_module).with('manufactured/rjr/loot')
      dispatch_manufactured_rjr_init(@d)
    end

    it "sets dispatcher on node" do
      dispatch_manufactured_rjr_init(@d)
      @rjr.node.dispatcher.should == @d
    end

    it "sets source_node message header on node" do
      dispatch_manufactured_rjr_init(@d)
      @rjr.node.message_headers['source_node'].should == 'manufactured'
    end

    it "creates the user" do
      dispatch_manufactured_rjr_init(@d)
      Users::RJR.registry.entity(&with_id(Manufactured::RJR.user.id)).should_not be_nil
    end

    context "user exists" do
      it "does not raise error" do
        Users::RJR.registry.entities << Manufactured::RJR.user
        lambda{
          dispatch_manufactured_rjr_init(@d)
        }.should_not raise_error
      end
    end

    it "adds additional privileges to user" do
      Manufactured::RJR::PRIVILEGES.each { |p,e|
        Manufactured::RJR.node.should_receive(:invoke).
          with('users::add_privilege',
               "user_role_#{Manufactured::RJR.user.id}",
                p, e)
      }
      Manufactured::RJR.node.should_receive(:invoke).at_least(1).and_call_original
      dispatch_manufactured_rjr_init(@d)
    end

    it "logs in the user using the node" do
      lambda{ # XXX @d.add_module above will have already called dispatch_init
        dispatch_manufactured_rjr_init(@d)
      }.should change{Users::RJR.registry.entities.size}.by(3)
      Users::RJR.registry.
                 entity(&matching{ |s| s.is_a?(Users::Session) &&
                                       s.user.id == Manufactured::RJR.user.id }).
                 should_not be_nil
    end

    it "sets session if on node" do
      dispatch_manufactured_rjr_init(@d)
      @rjr.node.message_headers['source_node'].should_not be_nil
    end

    it "add motel::on_movement callback to dispatcher" do
      @d.handles?('motel::on_movement').should be_false
      dispatch_manufactured_rjr_init(@d)
      @d.handles?('motel::on_movement').should be_true
    end

    it "add motel::on_rotation callback to dispatcher" do
      @d.handles?('motel::on_rotation').should be_false
      dispatch_manufactured_rjr_init(@d)
      @d.handles?('motel::on_rotation').should be_true
    end

    it "executes motel::on_movement/motel::on_rotation callbacks in Manufactured::RJR env" do
      dispatch_manufactured_rjr_init(@d)
      @d.environments['motel::on_movement'].should  == Manufactured::RJR
      @d.environments['motel::on_rotation'].should  == Manufactured::RJR
    end

  end

end # module Manufactured::RJR
