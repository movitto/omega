# client station tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/station'

module Omega::Client
  # nothing currently testable in Omega::Client::Station
  #describe Station do
  #  before(:each) do
  #    Omega::Client::Station.node.rjr_node = @n
  #    @s = Omega::Client::Station.new
  #  end
  #end # describe Station

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
      it "generates new id"

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
        s = stub(SolarSystem, :id => 42)
        SolarSystem.should_receive(:get).with(@f.system_id).and_return(s)
        s.should_receive(:closest_neighbor_with_no).and_return(s1)
        @f.should_receive(:jump_to).with(s1)
        @f.pick_system
      end
    end

    describe "#construction_args" do
      it "generates construction arguments from entity type"
    end
  end
end # module Omega::Client
