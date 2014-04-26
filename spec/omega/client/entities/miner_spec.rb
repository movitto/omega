# Omega Client Miner Tests
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/miner'

module Omega::Client
  describe Miner, :rjr => true do
    before(:each) do
      Omega::Client::Miner.node.rjr_node = @n

      setup_manufactured(nil, reload_super_admin)
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

    describe "resource_collected event" do
      before(:each) do
        @m = Omega::Client::Miner.new
        @m.entity = build(:ship)
      end

      it "subscribes to manufactured::subscribe_to event" do
        @m.node.should_receive(:invoke).
          with('manufactured::subscribe_to', @m.id, :resource_collected)
        @m.handle(:resource_collected)
      end

      it "listens for manufactured::event_occurred event" do
        @m.node.stub(:invoke)
        @m.node.should_receive(:handle).with('manufactured::event_occurred')
        @m.handle(:resource_collected)
      end

      it "adds resources to local entity" do
        res = build(:resource)
        @m.node.stub(:invoke)
        @m.handle(:resource_collected)
        @m.node.rjr_node.dispatcher.dispatch \
          :rjr_method => 'manufactured::event_occurred',
          :rjr_method_args => ['resource_collected', @m, res, 50]
        @m.resources.size.should == 1
        @m.resources.first.should == res
      end

      it "matches 'resource_collected <entity_id>'" do
        res = build(:resource)
        @m.node.stub(:invoke)
        @m.node.rjr_node.dispatcher.dispatch \
          :rjr_method => 'manufactured::event_occurred',
          :rjr_method_args => ['foo_bar', @m, res, 50]
        @m.node.rjr_node.dispatcher.dispatch \
          :rjr_method => 'manufactured::event_occurred',
          :rjr_method_args => ['resource_collected', build(:ship), res, 50]
        @m.resources.should be_empty
      end
    end

    describe "mining_stopped event" do
      before(:each) do
        @m = Omega::Client::Miner.new
        @m.entity = build(:ship)
      end

      it "subscribes to manufactured::subscribe_to event" do
        @m.node.should_receive(:invoke).
          with('manufactured::subscribe_to', @m.id, :mining_stopped)
        @m.handle(:mining_stopped)
      end

      it "listens for manufactured::event_occurred event" do
        @m.node.stub(:invoke)
        @m.node.should_receive(:handle).with('manufactured::event_occurred')
        @m.handle(:mining_stopped)
      end

      it "invokes entity.stop_mining" do
        res = build(:resource)
        @m.node.stub(:invoke)
        @m.handle(:mining_stopped)
        @m.entity.should_receive(:stop_mining)
        @m.node.rjr_node.dispatcher.dispatch \
          :rjr_method => 'manufactured::event_occurred',
          :rjr_method_args => ['mining_stopped', @m]
      end

      it "matches 'mining_stopped <entity_id>'" do
        res = build(:resource)
        @m.node.stub(:invoke)
        @m.handle(:mining_stopped)
        @m.entity.should_not_receive(:stop_mining)
        @m.node.rjr_node.dispatcher.dispatch \
          :rjr_method => 'manufactured::event_occurred',
          :rjr_method_args => ['foo_bar', @m]
        @m.node.rjr_node.dispatcher.dispatch \
          :rjr_method => 'manufactured::event_occurred',
          :rjr_method_args => ['mining_stopped', build(:ship)]
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
          @r.should_receive :offload_resources
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

      it "invokes manufactured::start_mining" do
        @n.should_receive(:invoke).with 'manufactured::start_mining', @r.id, @rs.id
        @r.mine @rs
      end

      it "updates local entity" do
        sh = create(:ship)
        @n.should_receive(:invoke).and_return(sh)
        @r.mine @rs
        @r.entity.should == sh
      end
    end

    describe "#start_bot" do
      before(:each) do
        s = create(:valid_ship, :type => :mining)
        @r = Miner.get(s.id)
      end

      it "starts listening for resource_collected events" do
        @r.should_receive(:handle).with(:resource_collected)
        @r.should_receive(:handle).at_least(:once)
        @r.start_bot
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
      before(:each) do
        s = create(:valid_ship, :type => :mining,
                   :location => build(:location, :x => 0, :y => 0, :z => 0))
        @r = Miner.get(s.id)
      end

      it "selects closest station" do
        s = create(:valid_station, :location => @r.location)
        @r.should_receive(:closest).with(:station).and_return([s])
        @r.should_receive(:select_target)
        @r.offload_resources
      end

      context "station is nil" do
        before(:each) do
          @r.should_receive(:closest).with(:station).and_return([])
        end

        it "raises :no_stations event" do
          @r.should_receive(:raise_event).with(:no_stations)
          @r.offload_resources
        end

        it "does not transfer" do
          @r.should_not_receive(:transfer_all_to)
          @r.offload_resources
        end

        it "does not select target" do
          @r.should_not_receive(:select_target)
          @r.offload_resources
        end

        it "does not move" do
          @r.should_not_receive(:move)
          @r.offload_resources
        end
      end

      context "closest station is within transfer distance" do
        it "transfers resources" do
          s = create(:valid_station, :location => @r.location)
          @r.should_receive(:closest).with(:station).and_return([s])
          @r.should_receive(:transfer_all_to).with(s)
          @r.should_receive(:closest).with(:resource).and_return([])
          @r.offload_resources
        end

        context "error during transfer" do
          it "refreshes stations" do
            s = create(:valid_station, :location => @r.location)
            @r.should_receive(:closest).with(:station).at_least(:once).and_return([s])
            @r.should_receive(:transfer_all_to).at_least(:once).and_raise(Exception)
            Omega::Client::Station.should_receive(:refresh).at_least(:once)
            @r.offload_resources
          end

          it "retries resource offloading twice" do
            s = create(:valid_station, :location => @r.location)
            @r.should_receive(:closest).with(:station).at_least(:once).and_return([s])
            @r.should_receive(:transfer_all_to).at_least(:once).and_raise(Exception)
            @r.should_receive(:offload_resources).exactly(3).times.and_call_original
            @r.offload_resources
          end

          context "all transfer retries fail" do
            it "raises transfer_err event" do
              s = create(:valid_station, :location => @r.location)
              @r.should_receive(:closest).with(:station).at_least(:once).and_return([s])
              @r.should_receive(:transfer_all_to).at_least(:once).and_raise(Exception)
              @r.should_receive(:raise_event).with(:transfer_err, s)
              @r.offload_resources
            end
          end
        end

        it "selects mining target" do
          s = create(:valid_station, :location => @r.location)
          @r.should_receive(:closest).with(:station).and_return([s])
          @r.should_receive(:transfer_all_to).with(s)
          @r.should_receive(:select_target)
          @r.offload_resources
        end
      end

      it "moves to closest station" do
        s = create(:valid_station, :location => @r.location + [10000,0,0])
        @r.should_receive(:closest).with(:station).and_return([s])
        @r.should_receive(:move_to).with(:destination => s)
        @r.offload_resources
      end

      it "raises moving_to event" do
        s = create(:valid_station, :location => @r.location + [10000,0,0])
        @r.should_receive(:closest).with(:station).and_return([s])
        @r.should_receive(:raise_event).with(:moving_to, s)
        @r.offload_resources
      end

      context "arrived at closest station" do
        it "transfers resources" do
          s = create(:valid_station, :location => @r.location + [10000,0,0])
          @r.should_receive(:closest).with(:station).twice.and_return([s])
          @r.offload_resources
          s.location.x = 0
          @r.should_receive(:transfer_all_to).with(s)
          @r.should_receive(:closest).with(:resource).and_return([])
          @r.raise_event(:movement)
        end

        it "selects mining target" do
          s = create(:valid_station, :location => @r.location + [10000,0,0])
          @r.should_receive(:closest).with(:station).twice.and_return([s])
          @r.offload_resources
          s.location.x = 0
          @r.should_receive(:transfer_all_to).with(s)
          @r.should_receive(:select_target)
          @r.raise_event(:movement)
        end
      end
    end

    describe "#select_target" do
      before(:each) do
        s = create(:valid_ship, :type => :mining,
                   :location => build(:location, :x => 0, :y => 0, :z => 0))
        @r = Miner.get(s.id)

        @cast = create(:asteroid,
                       :location => build(:location, :coordinates => [0,0,0]))
        @cres = create(:resource, :entity => @cast, :quantity => 10)
        @cast.set_resource @cres

        @fast = create(:asteroid,
                       :location => build(:location, :coordinates => [s.mining_distance+100,0,0]))
        @fres = create(:resource, :entity => @fast, :quantity => 10)
        @fast.set_resource @fres
      end

      it "selects closest resource" do
        @r.should_receive(:closest).with(:resource).and_return([])
        @r.select_target
      end

      context "no resources found" do
        it "raises no_resources event" do
          @r.should_receive(:closest).with(:resource).and_return([])
          @r.should_receive(:raise_event).with(:no_resources)
          @r.select_target
        end

        it "just returns" do
          @r.should_receive(:closest).with(:resource).and_return([])
          @r.should_not_receive(:move_to)
          @r.should_not_receive(:mine)
          @r.select_target
        end
      end

      it "raises selected_resource event" do
        @r.should_receive(:closest).with(:resource).and_return([@cast])
        @r.should_receive(:raise_event).with(:selected_resource, @cast)
        @r.select_target
      end

      context "closest resource withing mining distance" do
        it "starts mining resource" do
          @r.should_receive(:closest).with(:resource).and_return([@cast])
          @r.should_receive(:mine).with(@cres)
          @r.select_target
        end
      end

      #context "error during mining" do
      #  it "selects mining target" do
      #    @r.should_receive(:closest).with(:resource).and_return([@cast])
      #    @r.should_receive(:mine).with(@cres).and_raise(Exception)
      #    @r.should_receive(:select_target) # XXX
      #    @r.select_target
      #  end
      #end

      it "moves to closes resource" do
        @r.should_receive(:closest).with(:resource).and_return([@fast])
        @r.should_receive(:move_to)
        @r.select_target
      end

      context "arrived at closest resource" do
        it "starts mining resource" do
          @r.should_receive(:closest).with(:resource).and_return([@fast])
          @r.select_target
          @r.should_receive(:mine).with(@fres)
          @r.raise_event :movement
        end

      #  context "error during mining" do
      #    it "selects mining target" do
      #    @r.should_receive(:closest).with(:resource).and_return([@fast])
      #    @r.select_target
      #    @r.should_receive(:mine).with(@fast).and_raise(Exception)
      #    @r.should_receive(:select_target)
      #    @r.raise_event :movement
      #    end
      #  end
      end
    end

  end # describe Miner
end # module Omega::Client
