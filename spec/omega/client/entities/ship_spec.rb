# client ship tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client2/entities/ship'

module Omega::Client
  describe Ship do
    before(:each) do
      Omega::Client::Ship.node.rjr_node = @n
      @s = Omega::Client::Ship.new
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
    end
  end # describe Ship

  describe Miner do
    before(:each) do
      Omega::Client::Miner.node.rjr_node = @n
      @m = Omega::Client::Miner.new

      setup_manufactured(nil)
      add_role @login_role, :superadmin
    end

    describe "#validatation" do
      it "ensures ship.type == :mining" do
        s1 = create(:valid_ship, :type => :mining)
        s2 = create(:valid_ship, :type => :frigate)
        r = Miner.get_all
        r.size.should == 1
        r.first.id.should == s1.id
      end
    end

    describe "#cargo_full" do
      before(:each) do
        s = create(:valid_ship, :type => :mining)
        @r = Miner.get(s.id)
      end

      context "entity cargo full" do
        it "sets entity to :cargo_full state" do
          @r.should_receive(:cargo_full?).and_return(true)
          @r.raise_event(:anything)
          @r.states.should include(:cargo_full)
        end

        it "offloads resources" do
          @r.should_receive(:cargo_full?).and_return(true)
          @r.should_receive :offload_resources
          @r.raise_event(:anything)
        end
      end

      context "entity cargo not full" do
        it "removes entity from :cargo_full state" do
          @r.should_receive(:cargo_full?).and_return(false)
          @r.raise_event(:anything)
          @r.states.should_not include(:cargo_full)
        end
      end
    end

    describe "#mine" do
      before(:each) do
        s = create(:valid_ship, :type => :mining)
        @rs = create(:resource)
        @r = Miner.get(s.id)
      end

      it "adds resource collected handler" do
        @r.event_handlers[:resource_collected].size.should == 0
        @r.mine @rs
        @r.event_handlers[:resource_collected].size.should == 1
        @r.mine @rs
        @r.event_handlers[:resource_collected].size.should == 1
      end

      context "resource collected" do
        it "TODO"
      end

      it "invokes manufactured::start_mining" do
        @n.should_receive(:invoke).with 'manufactured::subscribe_to', @r.id, :resource_collected
        @n.should_receive(:invoke).with 'manufactured::start_mining', @r.id, @rs.id
        @r.mine @rs
      end
    end

    describe "#start_bot" do
      before(:each) do
        s = create(:valid_ship, :type => :mining)
        @r = Miner.get(s.id)
      end

      it "adds mining stopped handler" do
        @r.event_handlers[:mining_stopped].size.should == 0
        @r.start_bot 
        @r.event_handlers[:mining_stopped].size.should == 1
      end

      context "cargo full" do
        it "offloads resources" do
          @r.should_receive(:cargo_full?).and_return(true)
          @r.should_receive(:offload_resources)
          @r.start_bot
        end
      end

      context "cargo not full" do
        it "selects mining target" do
          @r.should_receive(:cargo_full?).and_return(false)
          @r.should_receive(:select_target)
          @r.start_bot
        end
      end
    end

    describe "#offload_resources" do
      it "selects closest station"

      context "closest station is within transfer distance" do
        it "transfers resources"
        it "selects mining target"
      end

      it "moves to closest station"

      context "arrived at closest station" do
        it "transfers resources"
        it "selects mining target"
      end
    end

    describe "#select_target" do
      it "selects closest resource"

      context "no resources found" do
        it "raises no_resources event"
        it "just returns"
      end

      it "raises selected_resource event"

      context "closest resource withing mining distance" do
        it "starts mining resource"
      end

      context "error during mining" do
        it "selects mining target"
      end

      it "moves to closes resource"
      
      context "arrived at closest resource" do
        it "starts mining resource"

        context "error during mining" do
          it "selects mining target"
        end
      end
    end

  end # describe Miner

  describe Corvette do
    before(:each) do
      Omega::Client::Corvette.node.rjr_node = @n
      @m = Omega::Client::Corvette.new

      setup_manufactured(nil)
      add_role @login_role, :superadmin
    end

    describe "#validatation" do
      it "ensures ship.type == :corvette" do
        s1 = create(:valid_ship, :type => :corvette)
        s2 = create(:valid_ship, :type => :frigate)
        r = Corvette.get_all
        r.size.should == 1
        r.first.id.should == s1.id
      end
    end
  end # describe Corvette

end # module Omega::Client
