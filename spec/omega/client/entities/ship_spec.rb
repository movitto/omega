# Omega Client Ship Tests
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/ship'

module Omega::Client
  describe Ship, :rjr => true do
    before(:each) do
      Omega::Client::Ship.node.rjr_node = @n
      @s = Omega::Client::Ship.new
    end

    describe "#destroyed" do
      context "entity not alive" do
        it "clears event handlers" do
          @s.should_receive(:clear_handlers)
          @s.class.send :init_entity, @s
          @s.set_state(:destroyed)
        end
      end
    end

    describe "#dock_to" do
      it "invokes manufactured::dock" do
        st = build(:station)
        @s.stub(:id).and_return(42)
        @s.node.should_receive(:invoke).
                with('manufactured::dock', 42, st.id)
        @s.dock_to(st)
      end
    end

    describe "#undock" do
      it "invokes manufactured::undock" do
        @s.stub(:id).and_return(42)
        @s.node.should_receive(:invoke).
                with('manufactured::undock', 42)
        @s.undock
      end
    end

    describe "#collect_loot" do
      it "invokes manufactured::collect_loot" do
        l = build(:loot)
        @s.stub(:id).and_return(42)
        @s.node.should_receive(:invoke).
                with('manufactured::collect_loot', 42, l.id)
        @s.collect_loot(l)
      end

      it "updates local entity" do
        s = build(:ship)
        @s.stub(:id).and_return(42)
        @s.node.should_receive(:invoke).and_return(s)

        l = build(:loot)
        @s.collect_loot(l)
        @s.entity.should == s
      end
    end
  end # describe Ship
end # module Omega::Client
