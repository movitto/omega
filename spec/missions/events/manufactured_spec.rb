# Manufactured Event class tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/events/manufactured'
require 'manufactured/ship'
require 'manufactured/station'
require 'cosmos/resource'
require 'cosmos/entities/asteroid'

module Missions
module Events
describe Manufactured do
  describe "#initialize" do
    before(:each) do
      @attacker = ::Manufactured::Ship.new      :id => 'attacker'
      @defender = ::Manufactured::Ship.new      :id => 'defender'
      @miner    = ::Manufactured::Ship.new      :id => 'miner'
      @station  = ::Manufactured::Station.new   :id => 'station'
      @constru  = ::Manufactured::Station.new   :id => 'constru'

      @ast      = ::Cosmos::Entities::Asteroid.new :name => 'ast1'
      @rs       = ::Cosmos::Resource.new  :id   => 'rs',
                                          :entity => @ast,
                                          :quantity => 50

      # TODO test all manufactured callbacks, see API for list
      @events =
        [['destroyed_by', @attacker, @defender],
         ['resource_collected', @miner, @rs],
         ['collected_loot', @attacker, @rs]]
    end

    it "sets manufactured event id" do
      @events.each { |me|
         m = Missions::Events::Manufactured.new *me
         if ['defended_stopped', 'defended',
             'destroyed', 'mining_stopped'].include?(me[0])
           m.id.should == me[2].id + '_' + me[0]
         else
           m.id.should == me[1].id + '_' + me[0]
         end
       }
     end

    it "sets manufactured event args" do
      @events.each { |me|
         m = Missions::Events::Manufactured.new *me
         m.manufactured_event_args.should == me
       }
    end

    it "accepts event params" do
      m = Missions::Events::Manufactured.new :id => 'ship-destroyed'
      m.id.should == 'ship-destroyed'
    end

    it "accepts mnaufactured event args in the parameter hash" do
      s = build(:ship, :id => 'ship')
      m = Missions::Events::Manufactured.new 'manufactured_event_args' =>
            ['destroyed_by', s]
      m.manufactured_event_args.should == ['destroyed_by', s]
      m.id.should == 'ship_destroyed_by'
    end
  end

  describe "#to_json" do
    it "returns the event in json format" do
      m = Missions::Events::Manufactured.new 'manufactured_event_args' =>
            ['destroyed', 'ship']
      j = m.to_json
      j.should include('"json_class":"Missions::Events::Manufactured"')
      j.should include('"manufactured_event_args":["destroyed","ship"]')
    end
  end

end # describe Manufactured
end # module Events
end # module Missions
