# client ship tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/ship'

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

      it "updates local entity"
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

      context "resource collected" do
        it "TODO"
      end

      it "invokes manufactured::start_mining" do
        @n.should_receive(:invoke).with 'manufactured::start_mining', @r.id, @rs.id
        @r.mine @rs
      end

      it "updates local entity"
    end

    describe "#start_bot" do
      before(:each) do
        s = create(:valid_ship, :type => :mining)
        @r = Miner.get(s.id)
      end

      it "starts listening for resource_collected events"

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
        s = create(:valid_ship, :type => :mining, :transfer_distance => 50,
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
        it "raises :no_stations event"
        it "returns"
      end

      context "closest station is within transfer distance" do
        it "transfers resources" do
          s = create(:valid_station, :location => @r.location)
          @r.should_receive(:closest).with(:station).and_return([s])
          @r.should_receive(:transfer_all_to).with(s)
          @r.should_receive(:closest).with(:resource).and_return([])
          @r.offload_resources
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
        s = create(:valid_station, :location => @r.location + [100,0,0])
        @r.should_receive(:closest).with(:station).and_return([s])
        @r.should_receive(:move_to).with(:destination => s)
        @r.offload_resources
      end

      it "raises moving_to event" do
        s = create(:valid_station, :location => @r.location + [100,0,0])
        @r.should_receive(:closest).with(:station).and_return([s])
        @r.should_receive(:raise_event).with(:moving_to, s)
        @r.offload_resources
      end

      context "arrived at closest station" do
        it "transfers resources" do
          s = create(:valid_station, :location => @r.location + [100,0,0])
          @r.should_receive(:closest).with(:station).and_return([s])
          @r.offload_resources
          @r.should_receive(:transfer_all_to).with(s)
          @r.should_receive(:closest).with(:resource).and_return([])
          @r.raise_event(:movement)
        end

        it "selects mining target" do
          s = create(:valid_station, :location => @r.location + [100,0,0])
          @r.should_receive(:closest).with(:station).and_return([s])
          @r.offload_resources
          @r.should_receive(:transfer_all_to).with(s)
          @r.should_receive(:select_target)
          @r.raise_event(:movement)
        end
      end

      context "error during resource transfer" do
        it "retries offload_resources"
      end
    end

    describe "#select_target" do
      before(:each) do
        s = create(:valid_ship, :type => :mining, :mining_distance => 50,
                   :location => build(:location, :x => 0, :y => 0, :z => 0))
        @r = Miner.get(s.id)

        @cast = create(:asteroid,
                       :location => build(:location, :coordinates => [0,0,0]))
        @cres = create(:resource, :entity => @cast, :quantity => 10)
        @cast.set_resource @cres

        @fast = create(:asteroid,
                       :location => build(:location, :coordinates => [100,0,0]))
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

    context "initialization" do
      it "starts async corvette proximity checker"
      it "periodically checks proximity for all local corvettes"
    end

    describe "#attack" do
      before(:each) do
        c = create(:valid_ship, :type => :corvette)
        @s = create(:valid_ship, :type => :frigate)
        @c = Corvette.get(c.id)
      end

      it "invokes manufactured::attack_entity" do
        @n.should_receive(:invoke).with 'manufactured::attack_entity', @c.id, @s.id
        @c.attack @s
      end
    end

    describe "#start_bot" do
      before(:each) do
        c = create(:valid_ship, :type => :corvette)
        @c = Corvette.get(c.id)
      end

      it "initializes visited systems list" do
        @c.should_receive(:patrol_route)
        @c.start_bot
        @c.visited.should == []
      end

      it "starts patrol route" do
        @c.should_receive(:patrol_route)
        @c.start_bot
      end
    end

    describe "#patrol_route" do
      before(:each) do
        @sys1 = create(:solar_system)
        @sys2 = create(:solar_system)
        @sys3 = create(:solar_system)
        jg1 = create(:jump_gate, :solar_system => @sys1, :endpoint => @sys2)
        jg2 = create(:jump_gate, :solar_system => @sys1, :endpoint => @sys3)

        c = create(:valid_ship, :type => :corvette, :solar_system => @sys1)
        @c = Corvette.get(c.id)
        @c.visited = []
      end

      it "adds current system to visited list" do
        @c.patrol_route
        @c.visited.collect { |v| v.id }.should include(@c.solar_system.id)
      end

      context "all neighboring systems visited" do
        it 'resets visited list' do
          @c.visited << @sys2
          @c.visited << @sys3
          @c.patrol_route

          # XXX patrol_route ^ will invoke patrol_route
          # again, adding current system to list
          @c.visited.collect { |v| v.id }.should == [@c.solar_system.id]
        end

        #it "restarts patrol route" do
        #  @c.visited << @sys2
        #  @c.visited << @sys3
        #  @c.should_receive :patrol_route # XXX
        #  @c.patrol_route
        #end
      end

      it "moves to jump gate" do
        @c.should_receive(:move_to)
        @c.patrol_route
      end

      context "on arrival at jump gate" do
        it 'jumps to next system' do
          @c.should_receive(:jump_to)
          @c.patrol_route
          @c.raise_event(:movement)
        end

        #it "continues patrol route" do
        #  @c.should_receive(:jump_to)
        #  @c.should_receive(:patrol_route)
        #  @c.patrol_route
        #  @c.raise_event(:movement)
        #end
      end
    end

    describe "#check_proximity" do
      before(:each) do
        c  = create(:valid_ship, :type => :corvette)
        @c = Corvette.get(c.id)
      end

      it "retrieves locations within attacking distance of ship" do
        @n.should_receive(:invoke).
           with('motel::get_location', 'with_id', @c.entity.location.id).
           and_return(@c.entity.location)
        @n.should_receive(:invoke).
           with('motel::get_locations', 'within', @c.attack_distance,
                'of', @c.entity.location).and_call_original
        @c.check_proximity
      end

      it "retrieves ships corresponding to locations" do
        @n.should_receive(:invoke).
           with('motel::get_location', 'with_id', @c.entity.location.id).
           and_return(@c.entity.location)

        locs = [build(:location), build(:location)]
        @n.should_receive(:invoke).
           with('motel::get_locations', 'within', @c.attack_distance,
                'of', @c.entity.location).and_return(locs)
        locs.each { |loc|
          @n.should_receive(:invoke).
             with('manufactured::get_entity', 'of_type', 'Manufactured::Ship',
                  'with_location', loc.id)
        }
        @c.check_proximity
      end

      context "ship belongs to another user" do
        before(:each) do
          l = build(:location)
          l.coordinates = @c.location.coordinates
          @o = create(:valid_ship, :user_id => create(:user).id,
                                   :location => l, :solar_system => @c.solar_system)
        end

        it "stops moving" do
          @c.should_receive(:stop_moving)
          @c.check_proximity
        end

        it "handles attacked_stop event" do
          @c.should_receive(:handle).with(:attacked_stop)
          @c.check_proximity
        end

        it "attacks ship" do
          @c.should_receive(:attack).with{ |*a| a[0].id.should == @o.id }
          @c.check_proximity
        end

        context "attacked_stop" do
          it "resumes patrol route" do
            @c.should_receive :patrol_route
            @c.check_proximity
            @c.raise_event :attacked_stop
          end
        end
      end
    end

  end # describe Corvette

end # module Omega::Client
