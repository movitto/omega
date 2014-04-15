# Client Factory Tests
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/factory'
require 'omega/client/entities/solar_system'

module Omega::Client
  describe Factory, :rjr => true do
    before(:each) do
      Omega::Client::Factory.node.rjr_node = @n

      setup_manufactured(nil, reload_super_admin)

      f = create(:valid_station, :type => :manufacturing)
      @f = Omega::Client::Factory.get(f.id)
    end

    describe "#validation" do
      it "ensures station.type == :manufacturing" do
        s = create(:valid_station, :type => :research)
        r = Factory.get_all
        r.size.should == 1
        r.first.id.should == @f.id
      end
    end

    describe "#construct" do
      it "invokes manufactured::construct_entity" do
        @n.should_receive(:invoke)
          .with('manufactured::construct_entity', @f.id, :foo, :bar)
        @f.construct :foo => :bar
      end

      it "raises :constructed event" do
        o = Object.new
        @n.should_receive(:invoke)
          .with('manufactured::construct_entity', @f.id).and_return(o)
        @f.should_receive(:raise_event).with(:constructed, o)
        @f.construct
      end

      it "returns constructed entity" do
        o = Object.new
        @n.should_receive(:invoke)
          .with('manufactured::construct_entity', @f.id).and_return(o)
        r = @f.construct
        r.should == o
      end
    end

    describe "#entity_type" do
      it 'sets/gets entity type' do
        @f.entity_type = :foo
        @f.entity_type.should == :foo
      end
    end

    describe "#start_bot" do
      it "starts construction" do
        @f.should_receive :start_construction
        @f.start_bot
      end

      it "registers :received event handler" do
        @f.start_bot
        @f.handles?(:transferred_from).should be_true
      end

      context "resources received" do
        it "starts construction" do
          @f.should_receive(:start_construction).twice
          @f.start_bot
          @f.raise_event(:transferred_from)
        end
      end
    end

    describe "#start_construction" do
      context "station cannot construct entity" do
        it "does nothing" do
          @f.should_receive(:can_construct?).and_return(false)
          @f.should_not_receive :construct
          @f.start_construction
        end
      end

      context "station can construct entity" do
        it "constructs entity" do
          @f.should_receive(:can_construct?).and_return(true)
          @f.should_receive :construct
          @f.start_construction
        end
      end

      it "generates new id" do
        @f.should_receive(:can_construct?).and_return(true)
        @f.should_receive(:construct).with { |e| e[:id].should =~ UUID_PATTERN }
        @f.start_construction
      end
    end

    describe "#pick_system" do
      it "retrieves systems with no stations" do
        s = create(:solar_system)
        SolarSystem.should_receive(:get).with(@f.system_id).and_return(s)
        s.should_receive(:closest_neighbor_with_no).with { |s|
          s[:type].should == 'Manufactured::Station'
          s[:owned_by].should == @f.user_id
        }.and_return(s)
        @f.pick_system
      end

      context "all systems have stations" do
        it "retrieves system with fewest stations" do
          s = create(:solar_system)
          SolarSystem.should_receive(:get).with(@f.system_id).and_return(s)
          s.should_receive(:closest_neighbor_with_no).and_return(nil)
          SolarSystem.should_receive(:with_fewest).with({:type => 'Manufactured::Station', :owned_by => @f.user_id}).and_return(s)
          @f.pick_system
        end
      end

      it "jumps to system" do
        s1 = build(:solar_system)
        s = double(SolarSystem, :id => 42)
        SolarSystem.should_receive(:get).with(@f.system_id).and_return(s)
        s.should_receive(:closest_neighbor_with_no).and_return(s1)
        @f.should_receive(:jump_to).with(s1)
        @f.pick_system
      end
    end

    describe "#construction_args" do
      context "entity type is 'factory'" do
        it "returns manufacturing station init args" do
          expected = {:entity_type => 'Station', :type  => :manufacturing}
          @f.entity_type 'factory'
          @f.construction_args.should == expected
        end
      end

      context "entity type is 'miner'" do
        it "returns mining init args" do
          expected = {:entity_type => 'Ship', :type  => :mining}
          @f.entity_type 'miner'
          @f.construction_args.should == expected
        end
      end

      context "entity type is 'corvette'" do
        it "returns corvette init args" do
          expected = {:entity_type => 'Ship', :type  => :corvette}
          @f.entity_type 'corvette'
          @f.construction_args.should == expected
        end
      end
    end
  end
end # module Omega::Client
