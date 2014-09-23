# manufactured/rjr/motel_callback tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/motel_callback'
require 'motel/movement_strategies/linear'
require 'motel/movement_strategies/rotate'

module Manufactured::RJR
  describe "#motel_callback", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured  :MOTEL_CALLBACK_METHODS

      @sh = create(:valid_ship)
    end

    context "not local node" do
      it "raises PermissionError" do
        @n.node_type = 'local-test'
        lambda {
          @s.motel_callback 'anything'
        }.should raise_error(PermissionError)
      end
    end

    context "entity not found" do
      it "does not raise error" do
        lambda {
          @s.motel_callback build(:location)
        }.should_not raise_error
      end
    end

    it "updates use DistanceTravelled attribute" do
      enable_attributes {
        ms = Motel::MovementStrategies::Linear.new :speed => 1
        @sh.distance_moved = 500.1
        @sh.location.movement_strategy = ms
        @registry.update @sh, &with_id(@sh.id)

        @s.motel_callback @sh.location
        Users::RJR.registry.entity(&with_id(@sh.user_id)).
          attribute(Users::Attributes::DistanceTravelled.id).
          total.should == 500.1
      }
    end

    it "updates entity with location" do
      loc = build(:location, :id => @sh.location.id)
      @s.motel_callback loc
      @registry.entity(&with_id(@sh.id)).location.should == loc
    end

    it "returns nil" do
      @s.motel_callback(@sh.location)
    end
  end

end # module Manufactured::RJR
