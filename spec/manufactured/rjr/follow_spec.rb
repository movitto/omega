# manufactured::follow_entity specs
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/follow'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#follow_entity", :rjr => true do
    include Omega::Server::DSL
    include Manufactured::RJR

    before(:each) do
      setup_manufactured :FOLLOW_METHODS

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
        }.should_not raise_error
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

  describe "#dispatch_manufactured_rjr_follow" do
    it "adds manufactured::follow_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_follow(d)
      d.handlers.keys.should include("manufactured::follow_entity")
    end
  end
end
