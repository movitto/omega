# client cosmos_entity module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/cosmos'
require 'omega/client/entities/station'

# Test data used in this module
module OmegaTest
  class InSystem
    include Omega::Client::Trackable
    include Omega::Client::InSystem
  end

  class HasCargo
    include Omega::Client::Trackable
    include Omega::Client::HasCargo
  end
end

module Omega::Client
  describe SolarSystem do
    before(:each) do
      Omega::Client::SolarSystem.node.rjr_node = @n

      setup_manufactured(nil)
      add_role @login_role, :superadmin
    end

    describe "#jump_gates" do
      it "caches jump gate endpoints" do
        rsys = Cosmos::Entities::SolarSystem.new :id => 'rsys'
        sys = Cosmos::Entities::SolarSystem.new :children =>
                [Cosmos::Entities::JumpGate.new(:id => 'jg1', :endpoint => rsys),
                 Cosmos::Entities::JumpGate.new(:id => 'jg2', :endpoint_id => 'rem_sys')]

        s = Omega::Client::SolarSystem.new
        s.entity = sys
        SolarSystem.should_receive(:cached).with('rem_sys').once
        SolarSystem.should_not_receive(:cached).with('rsys')
        s.jump_gates.should == s.jump_gates
      end
    end

    describe "#asteroids" do
      it "retrieves asteroid resources" do
        sys  = Cosmos::Entities::SolarSystem.new :children =>
                [Cosmos::Entities::Asteroid.new(:id => 'ast1')]

        s = Omega::Client::SolarSystem.new
        s.entity = sys

        @n.should_receive(:invoke).with('cosmos::get_resources', 'ast1').and_return(:res)
        s.asteroids.should == sys.asteroids
        sys.asteroids.first.resources.should == :res
      end
    end

    describe "#entities" do
      it "retrieves entities in system" do
        e = Cosmos::Entities::SolarSystem.new
        s = Omega::Client::SolarSystem.new
        s.entity = e
        @n.should_receive(:invoke).with('manufactured::get_entities', 'under', s.id).
                                   and_return([:ent])
        s.entities.should == [:ent]
      end
    end

    describe "#with_fewest" do
      context "entity_type == station" do
        it 'returns systems sorted by number of user_owned stations in them' do
          sys1 = create(:solar_system)
          sys2 = create(:solar_system)
          s1 = create(:valid_station, :user_id => @login_user.id, :solar_system => sys1)

          sys = Omega::Client::SolarSystem.with_fewest :type => "Manufactured::Station",
                                                       :owned_by => @login_user.id
          sys.should_not be_nil
          sys.id.should == sys1.id
        end
      end
    end

    describe "#closest_neighbor_with_no" do
      context "entity_type == station" do
        it "returns closest system with no user owned station" do
          sys1 = create(:solar_system)
          sys2 = create(:solar_system)
          sys3 = create(:solar_system)
          create(:jump_gate, :solar_system => sys1, :endpoint => sys2)
          create(:jump_gate, :solar_system => sys1, :endpoint => sys3)
          s1 = create(:valid_station, :solar_system => sys2, :user_id => @login_user.id)

          c = Omega::Client::SolarSystem.get(sys1.id)
          n = c.closest_neighbor_with_no :type => "Manufactured::Station",
                                         :owned_by => @login_user.id
          n.id.should == sys3.id
        end
      end

      context "no matching systems" do
        it "returns nil" do
          sys1 = create(:solar_system)
          sys2 = create(:solar_system)
          create(:jump_gate, :solar_system => sys1, :endpoint => sys2)
          s1 = create(:valid_station, :solar_system => sys2, :user_id => @login_user.id)

          c = Omega::Client::SolarSystem.get(sys1.id)
          n = c.closest_neighbor_with_no :type => "Manufactured::Station",
                                         :owned_by => @login_user.id
          n.should be_nil
        end
      end
    end
  end # describe SolarSystem

  describe InSystem do
    before(:each) do
      OmegaTest::InSystem.node.rjr_node = @n
      @i = OmegaTest::InSystem.new

      setup_manufactured(nil)
      add_role @login_role, :superadmin
    end

    describe "#solar_system" do
      it "retrieves system from the server" do
        @i.entity = stub(Object)
        @i.entity.stub(:parent_id).and_return('system1')
        SolarSystem.should_receive(:cached).with('system1')
        @i.solar_system
      end
    end

    describe "#closest" do
      context "type == station" do
        before(:each) do
          sys1 = create(:solar_system)
          sys2 = create(:solar_system)
          st1  = create(:valid_station, :solar_system => sys1,
                                        :location     => build(:location, :x => 10))
          st2  = create(:valid_station, :solar_system => sys1)
          st3  = create(:valid_station, :solar_system => sys2)
          @sts  = Omega::Client::Station.get_all

          @i.entity = build(:valid_station)
          @i.location.parent_id = sys1.location.id
        end

        it "retrieves list of stations in current system sorted by distance" do
          @i.closest(:station).should == [@sts[1], @sts[0]]
        end

        context "user_owned == true" do
          it "only retrieves user owned entities"
        end
      end

      context "type == resource" do
        before(:each) do
          sys1 = create(:solar_system)
          sys2 = create(:solar_system)
          @ast1 = create(:asteroid, :solar_system => sys1,
                        :location => build(:location, :x => 20, :y => 0, :z => 0))
          @ast2 = create(:asteroid, :solar_system => sys1,
                        :location => build(:location, :x => 0,  :y => 0, :z => 0))
          @ast3 = create(:asteroid, :solar_system => sys1)
          @ast4 = create(:asteroid, :solar_system => sys2)
          @res1 = create(:resource, :entity => @ast1, :quantity => 10)
          @res2 = create(:resource, :entity => @ast1, :quantity => 5)
          @res3 = create(:resource, :entity => @ast2, :quantity => 5)
          @res4 = create(:resource, :entity => @ast4, :quantity => 5)

          @i.entity = create(:valid_station, :solar_system => sys1,
                             :location => build(:location, :x => 0, :y => 0, :z => 0))
        end

        it "retrieves list of asteroids w/ resources in current system sorted by distance" do
          r = @i.closest(:resource)
          r.all? { |ri| ri.should be_an_instance_of(Cosmos::Entities::Asteroid) }
          r = r.collect { |ri| ri.id }
          r.should == [@ast2.id, @ast1.id]
        end
      end
    end

    describe "#move_to" do
      before(:each) do
        @i.entity = create(:valid_ship)
        setup_manufactured(nil)
        add_role @login_role, :superadmin
      end

      it "clears movement handlers" do
        h = proc {}
        @i.handle(:movement, &h)
        @i.event_handlers[:movement].should include(h)
        @i.move_to :location => build(:location)
        @i.event_handlers[:movement].should_not include(h)
      end

      it "handlers movement event" do
        h = proc {}
        @i.move_to :location => build(:location), &h
        @i.event_handlers[:movement].should == [h]
      end

      it "invokes manufactured::move_entity" do
        l = build(:location)
        @i.node.should_receive(:invoke).
                with{ |*a|
                  a[0].should == 'manufactured::move_entity'
                  a[1].should == @i.entity.location.id
                  a[2].coordinates.should == l.coordinates
                  a[2].parent_id.should == @i.location.parent_id
                }
        @i.move_to :location => l
      end

      context "destination == :closest station" do
        it "retrieves location to move from closest(:station)" do
          l = build(:location)
          st = Manufactured::Station.new(:location => l)
          @i.should_receive(:closest).with(:station).and_return(st)
          @i.node.should_receive(:invoke).
                  with{ |*a|
                    a[0].should == 'manufactured::move_entity'
                    a[1].should == @i.entity.location.id
                    a[2].coordinates.should == l.coordinates
                    a[2].parent_id.should == @i.location.parent_id
                  }
          @i.move_to :destination => :closest_station
        end
      end

      context "destination = other" do
        it "retrieves location to move from destination.location" do
          l = build(:location)
          st = Manufactured::Station.new(:location => l)
          @i.node.should_receive(:invoke).
                  with{ |*a|
                    a[0].should == 'manufactured::move_entity'
                    a[1].should == @i.entity.location.id
                    a[2].coordinates.should == l.coordinates
                    a[2].parent_id.should == @i.location.parent_id
                  }
          @i.move_to :destination => st
        end
      end
    end

    describe "#stop_moving" do
      before(:each) do
        @l = build(:location)
        @i.stub(:id).and_return(42)
      end

      it "invokes manufactured::stop_entity" do
        @i.node.should_receive(:invoke).with('manufactured::stop_entity', 42)
        @i.stop_moving
      end
    end

    describe "jump_to" do
      before(:each) do
        @i.entity = create(:valid_ship)
        setup_manufactured(nil)
        add_role @login_role, :superadmin
      end

      context "system is a string" do
        it "retrieves destination system from server" do
          s = create(:solar_system)
          @i.node.should_receive(:invoke).with('cosmos::get_entity', 'with_id', s.id).and_call_original
          @i.node.should_receive(:invoke) # move entity
          @i.jump_to s.id
        end
      end

      it "invokes manufactured::move_entity" do
        s = create(:solar_system)
        @i.node.should_receive(:invoke).with{ |*a|
          a[0].should == 'manufactured::move_entity'
          a[1].should == @i.entity.id
          a[2].parent_id.should == s.location.id
        }
        @i.jump_to s
      end

      it "updates local entity" do
        s = create(:solar_system)
        @i.node.should_receive(:invoke).and_return(:foo)
        @i.jump_to s
        @i.entity.should == :foo
      end

      it "raises :jumped event" do
        s = create(:solar_system)
        @i.node.should_receive(:invoke).and_return(true)
        @i.should_receive(:raise_event).with(:jumped)
        @i.jump_to s
      end
    end

  end # describe InSystem

  describe HasCargo do
    before(:each) do
      OmegaTest::HasCargo.node.rjr_node = @n
      @h = OmegaTest::HasCargo.new

      @h.entity = create(:valid_ship)
      @h.entity.add_resource create(:resource, :id => 'gem-diamond', :quantity => 10)
      @h.entity.add_resource create(:resource, :id => 'gem-ruby',    :quantity => 15)
      setup_manufactured(nil)
      add_role @login_role, :superadmin

      @t = create(:valid_ship)
    end

    describe "#transfer_all_to" do
      it "invokes transfer with each local resource" do
        @h.entity.resources.each { |r|
          @h.should_receive(:transfer).with(r, @t)
        }
        @h.transfer_all_to(@t)
      end
    end

    describe "#transfer" do
      it "invokes manufactured::transfer_resource" do
        @h.node.should_receive(:invoke).
                with('manufactured::transfer_resource',
                     @h.entity.id, @t.id, @h.resources.first).
                and_return([@h, @t])
        @h.transfer @h.resources.first, @t
      end

      it "updates source/target entities" do
        @h.node.should_receive(:invoke).and_return([:foo, :bar])
        @h.transfer @h.resources.first, @t
        @h.entity.should == :foo
        #@t.entity.should == :bar
      end

      it "raises transfered event" do
        @h.node.should_receive(:invoke).and_return([@h, @t])
        @h.should_receive(:raise_event).with(:transferred_to, @t, @h.resources.first)
        @h.transfer @h.resources.first, @t
      end

      #it "raises received event"
    end
  end # describe HasCargo

end # module Omega::Client
