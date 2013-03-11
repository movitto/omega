# Manufactured Event class tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Missions::Events::Manufactured do
  it "should accept manufactured event args" do
    attacker = Manufactured::Ship.new      :id => 'attacker'
    defender = Manufactured::Ship.new      :id => 'defender'
    miner    = Manufactured::Ship.new      :id => 'miner'
    station  = Manufactured::Station.new   :id => 'station'
    constru  = Manufactured::Station.new   :id => 'constru'

    res      = Cosmos::Resource.new        :id   => 'res'
    ast      = Cosmos::Asteroid.new        :name => 'ast1'
    rs       = Cosmos::ResourceSource.new  :id   => 'rs',
                                           :entity => ast,
                                           :resource => res

    # TODO test all omega callbacks, see API for list
    m = Missions::Events::Manufactured.new 'attacked', attacker, defender
    m.id.should == attacker.id + '_attacked'
    m.manufactured_event_args.should == ['attacked', attacker, defender]
    m = Missions::Events::Manufactured.new 'attacked_stopped', attacker, defender
    m.id.should == attacker.id + '_attacked_stopped'
    m.manufactured_event_args.should == ['attacked_stopped', attacker, defender]

    m = Missions::Events::Manufactured.new 'defended', attacker, defender
    m.id.should == defender.id + '_defended'
    m.manufactured_event_args.should == ['defended', attacker, defender]
    m = Missions::Events::Manufactured.new 'defended_stopped', attacker, defender
    m.id.should == defender.id + '_defended_stopped'
    m.manufactured_event_args.should == ['defended_stopped', attacker, defender]
    m = Missions::Events::Manufactured.new 'destroyed', attacker, defender
    m.id.should == defender.id + '_destroyed'
    m.manufactured_event_args.should == ['destroyed', attacker, defender]

    m = Missions::Events::Manufactured.new 'resource_depleted', miner, rs
    m.id.should == miner.id + '_resource_depleted'
    m.manufactured_event_args.should == ['resource_depleted', miner, rs]
    m = Missions::Events::Manufactured.new 'mining_stopped', 'resource_depleted', miner, rs
    m.id.should == miner.id + '_mining_stopped'
    m.manufactured_event_args.should == ['mining_stopped', 'resource_depleted', miner, rs]
    m = Missions::Events::Manufactured.new 'resource_collected', miner, rs
    m.id.should == miner.id + '_resource_collected'
    m.manufactured_event_args.should == ['resource_collected', miner, rs]

    m = Missions::Events::Manufactured.new 'construction_complete', station, constru
    m.id.should == station.id + '_construction_complete'
    m.manufactured_event_args.should == ['construction_complete', station, constru]
    m = Missions::Events::Manufactured.new 'partial_construction', station, constru, 0.5
    m.id.should == station.id + '_partial_construction'
    m.manufactured_event_args.should == ['partial_construction', station, constru, 0.5]

    # TODO howto test timestamp is set to Time.now?
  end
end
