# manufactured::create_entity,manufactured::construct_entity tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/movement'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#move_entity_in_system" do
    include Omega::Server::DSL # for with_id below
    include Manufactured::RJR

    before(:each) do
      setup_manufactured :MOVEMENT_METHODS

      @sys  = create(:solar_system)
      @rsys = Cosmos::RJR.registry.safe_exec { |es| es.find &with_id(@sys.id) }

      @l   = build(:location, :coordinates => [0,0,0])
      @sh  = create(:valid_ship,
                    :solar_system => @sys,
                    :location => build(:location,
                                       :coordinates => [10,0,0]))
      @rsh = @registry.safe_exec { |es| es.find &with_id(@sh.id) }
    end

    context "entity is not a ship" do
      it "raises OperationError" do
        lambda {
          move_entity_in_system(create(:valid_station), @l)
        }.should raise_error(OperationError)
      end
    end

    context "ship is docked" do
      it "raises OperationError" do
        sh = create(:valid_ship, :docked_at => build(:station))
        lambda {
          move_entity_in_system(sh, @l)
        }.should raise_error(OperationError)
      end
    end

    context "ship is at location" do
      it "raises OperationError" do
        sh = create(:valid_ship, :location => @l)
        lambda {
          move_entity_in_system(sh, @l)
        }.should raise_error(OperationError)
      end
    end

    context "entity is facing destination" do
      it "moves entity towards destination" do
        @sh.location.coordinates = [100, 0, 0]
        @sh.location.orientation = [-1, 0, 0]
        move_entity_in_system(@sh, @l)
        @sh.location.movement_strategy.
           should be_an_instance_of(Motel::MovementStrategies::Linear)
        @sh.location.movement_strategy.dx.should == -1
        @sh.location.movement_strategy.dy.should == 0
        @sh.location.movement_strategy.dz.should == 0
      end
    end

    context "entity is not facing location" do
      before(:each) do
        @sh.location.coordinates = [100, 0, 0]
        @sh.location.orientation = [1, 0, 0]
      end

      it "rotates entity to face location" do
        move_entity_in_system(@sh, @l)
        @sh.location.movement_strategy.
          should be_an_instance_of(Motel::MovementStrategies::Rotate)
      end

      it "sets next movement strategy to move entity towards destination" do
        move_entity_in_system(@sh, @l)
        @sh.location.next_movement_strategy.
          should be_an_instance_of(Motel::MovementStrategies::Linear)
      end

      it "tracks rotation" do
        Manufactured::RJR.node.should_receive(:invoke).
                          with("motel::track_rotation", @sh.id, Math::PI, 0, 0, 1)
        Manufactured::RJR.node.should_receive(:invoke).
                          with("motel::track_movement", @sh.id, 100)
        Manufactured::RJR.node.should_receive(:invoke).
                          with("motel::update_location", an_instance_of(Motel::Location))
        move_entity_in_system(@sh, @l)
      end
    end

    it "tracks movement" do
      @sh.location.orientation = [-1, 0, 0]
      Manufactured::RJR.node.should_receive(:invoke).
                        with("motel::track_movement", @sh.id, 10.0)
      Manufactured::RJR.node.should_receive(:invoke).
                        with("motel::update_location", an_instance_of(Motel::Location))
      move_entity_in_system(@sh, @l)
    end
  end # describe #move_entity_in_system

  describe "#move_entity_between_systems" do
    include Omega::Server::DSL
    include Manufactured::RJR

    before(:each) do
      setup_manufactured :MOVEMENT_METHODS
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

    it "updates registry entity" do
      @registry.should_receive(:update).with(@sh).and_call_original
      move_entity_between_systems(@sh, @nsys)
      @rsh.system_id.should == @nsys.id
    end
  end # describe #move_entity_between_systems

  describe "#move_entity" do
    include Omega::Server::DSL
    include Manufactured::RJR

    before(:each) do
      setup_manufactured :MOVEMENT_METHODS

      @sys  = create(:solar_system)
      @rsys = Cosmos::RJR.registry.safe_exec { |es| es.find &with_id(@sys.id) }

      @l   = build(:location, :coordinates => [0,0,0])
      @sh  = create(:valid_ship,
                    :solar_system => @sys,
                    :location => build(:location,
                                       :coordinates => [10,0,0]))
      @rsh = @registry.safe_exec { |es| es.find &with_id(@sh.id) }

      @nsys = create(:solar_system)
      @rnsys = Cosmos::RJR.registry.safe_exec { |es| es.find &with_id(@nsys.id) }
    end

    context "invalid entity id specified" do
      it "raises DataNotFound" do
        lambda {
          @s.move_entity 'invalid', @l
        }.should raise_error(DataNotFound)
      end
    end

    context "invalid entity type specified" do
      it "raises ValidationError" do
        lambda {
          @s.move_entity create(:valid_loot).id, @l
        }.should raise_error(ValidationError)
      end
    end

    context "specified ship that is not alive" do
      it "raises ValidationError" do
        @rsh.hp = 0
        lambda {
          @s.move_entity @sh.id, @l
        }.should raise_error(ValidationError)
      end
    end

    context "insufficient permissions (modify entity)" do
      it "raises PermissionError" do
        lambda {
          @s.move_entity @sh.id, @l
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient permissions (modify entity)" do
      before(:each) do
        add_privilege @login_role, 'modify', 'manufactured_entities'
      end

      it "does not raise PermissionError" do
        lambda {
          @s.move_entity @sh.id, @l
        }.should_not raise_error(PermissionError)
      end

      context "invalid location" do
        it "raises DataNotFound" do
          @l.parent_id = 'nonexistant'
          lambda {
            @s.move_entity @sh.id, @l
          }.should raise_error(DataNotFound)
        end
      end

      context "invalid location type" do
        it "raises ValidationError" do
          @l.parent_id = @sys.galaxy.location.id
          lambda {
            @s.move_entity @sh.id, @l
          }.should raise_error(ValidationError)
        end
      end

      it "updates the entity's location and system" do
        @s.node.should_receive(:invoke).
           with('motel::get_location', 'with_id', @sh.location.id).
           and_call_original
        @s.node.should_receive(:invoke).
           with('cosmos::get_entity', 'with_location', @sys.location.id).
           and_call_original
        @s.node.should_receive(:invoke).at_least(2).times.and_call_original
        @s.move_entity @sh.id, @l
      end

      context "target system != entity system" do
        it "invokes move_entity_between_systems" do
          @l.parent_id = @nsys.location.id
          @s.should_receive(:move_entity_between_systems)
          @s.move_entity @sh.id, @l
        end
      end

      context "target system == entity system" do
        it "invokes move_entity_in_system" do
          @s.should_receive(:move_entity_in_system)
          @s.move_entity @sh.id, @l
        end
      end

      it "returns entity" do
        r = @s.move_entity @sh.id, @l
        r.should be_an_instance_of(Ship)
        r.id.should == @sh.id
      end
    end
  end # describe #move_entity

  describe "#follow_entity" do
    include Omega::Server::DSL
    include Manufactured::RJR

    before(:each) do
      setup_manufactured :MOVEMENT_METHODS

      @sys  = create(:solar_system)
      @rsys = Cosmos::RJR.registry.safe_exec { |es| es.find &with_id(@sys.id) }

      @sh  = create(:valid_ship,
                    :solar_system => @sys,
                    :location => build(:location,
                                       :coordinates => [10,0,0]))
      @rsh = @registry.safe_exec { |es| es.find &with_id(@sh.id) }
      @rshl = Motel::RJR.registry.safe_exec { |es| es.find &with_id(@sh.location.id) }

      @sh1 = create(:valid_ship,
                    :solar_system => @sys,
                    :location => build(:location,
                                       :coordinates => [0,0,0]))
      @rsh1= @registry.safe_exec { |es| es.find &with_id(@sh1.id) }
    end

    context "specified ids are same" do
      it "raises ArgumentError" do
        lambda {
          @s.follow_entity @sh.id, @sh.id, 10
        }.should raise_error(ArgumentError)
      end
    end

    context "invalid entity id specified" do
      it "raises DataNotFound" do
        lambda {
          @s.follow_entity 'invalid', @sh.id, 10
        }.should raise_error(DataNotFound)
      end
    end

    context "invalid entity class specified" do
      it "raises ArgumentError" do
        lambda {
          @s.follow_entity create(:valid_station).id, @sh.id, 10
        }.should raise_error(ArgumentError)
      end
    end

    context "invalid target id specified" do
      it "raises DataNotFound" do
        lambda {
          @s.follow_entity @sh.id, 'invalid', 10
        }.should raise_error(DataNotFound)
      end
    end

    context "invalid target class specified" do
      it "raises ArgumentError" do
        lambda {
          @s.follow_entity @sh.id, create(:valid_station).id, 10
        }.should raise_error(ArgumentError)
      end
    end

    context "invalid distance specified" do
      it "raises ArgumentError" do
        lambda {
          @s.follow_entity @sh.id, @sh1.id, "10"
        }.should raise_error(ArgumentError)

        lambda {
          @s.follow_entity @sh.id, @sh1.id, 0
        }.should raise_error(ArgumentError)
      end
    end

    context "insufficient permissions (view/modify manufactured_entities)" do
      it "raises PermissionError" do
        lambda {
          @s.follow_entity @sh.id, @sh1.id, 10
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient permissions (modify manufactured_entities)" do
      before(:each) do
        add_privilege @login_role, 'modify', 'manufactured_entities'
        add_privilege @login_role, 'view', 'manufactured_entities'
      end

      it "does not raise PermissionError" do
        lambda {
          @s.follow_entity @sh.id, @sh1.id, 10
        }.should_not raise_error(PermissionError)
      end

      it "updates entity & target location & system" do
        Manufactured::RJR.node.should_receive(:invoke).
               with("motel::get_location", 'with_id', @sh.id).
               and_call_original
        Manufactured::RJR.node.should_receive(:invoke).
               with("motel::get_location", 'with_id', @sh1.id).
               and_call_original
        Manufactured::RJR.node.should_receive(:invoke).
               with("cosmos::get_entity", 'with_location', @sh.parent.id).
               and_call_original
        Manufactured::RJR.node.should_receive(:invoke).
               with("cosmos::get_entity", 'with_location', @sh1.parent.id).
               and_call_original
        Manufactured::RJR.node.should_receive(:invoke).and_call_original
        @s.follow_entity @sh.id, @sh1.id, 10
      end

      context "entities are not in the same system" do
        it "raises ArgumentError" do
          nsys = create(:solar_system)
          @rshl.parent_id = nsys.location.id
          lambda {
            @s.follow_entity @sh.id, @sh1.id, 10
          }.should raise_error(ArgumentError)
        end
      end

      context "entity is docked" do
        it "raises OperationError" do
          @rsh.docked_at = create(:valid_station)
          lambda {
            @s.follow_entity @sh.id, @sh1.id, 10
          }.should raise_error(OperationError)
        end
      end

      it "updates entity movement strategy in motel" do
        @rshl.movement_strategy.should == Motel::MovementStrategies::Stopped.instance
        @s.follow_entity @sh.id, @sh1.id, 10
        @rshl.movement_strategy.
          should be_an_instance_of(Motel::MovementStrategies::Follow)
      end

      it 'returns entity"'do
        r = @s.follow_entity @sh.id, @sh1.id, 10
        r.should be_an_instance_of(Manufactured::Ship)
        r.id.should == @sh.id
        r.location.ms.should be_an_instance_of(Motel::MovementStrategies::Follow)
      end
    end
  end # describe #follow_entity

  describe "#stop_entity" do
    include Omega::Server::DSL

    before(:each) do
      setup_manufactured :MOVEMENT_METHODS

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
        }.should_not raise_error(PermissionError)
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


  describe "#dispatch_manufactured_rjr_movement" do
    it "adds manufactured::move_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_movement(d)
      d.handlers.keys.should include("manufactured::move_entity")
    end

    it "adds manufactured::follow_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_movement(d)
      d.handlers.keys.should include("manufactured::follow_entity")
    end

    it "adds manufactured::stop_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_movement(d)
      d.handlers.keys.should include("manufactured::stop_entity")
    end
  end

end #module Manufactured::RJR
