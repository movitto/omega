# manufactured::move_entity specs
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/move'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#move_entity", :rjr => true do
    include Omega::Server::DSL
    include Manufactured::RJR

    before(:each) do
      setup_manufactured :MOVE_METHODS

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
        }.should_not raise_error
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

  describe "#dispatch_manufactured_rjr_move" do
    it "adds manufactured::move_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_move(d)
      d.handlers.keys.should include("manufactured::move_entity")
    end
  end
end
