# registry module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

require 'stringio'

describe Manufactured::Registry do

  before(:each) do
    Manufactured::Registry.instance.init
  end

  after(:each) do
    Manufactured::Registry.instance.terminate
  end

  it "provide acceses to managed manufactured entities" do
    Manufactured::Registry.instance.ships.size.should == 0
    Manufactured::Registry.instance.stations.size.should == 0
    Manufactured::Registry.instance.fleets.size.should == 0


    system1 = Cosmos::SolarSystem.new :name => 'system1'
    system2 = Cosmos::SolarSystem.new :name => 'system2'
    ship1  = Manufactured::Ship.new :id => 'ship1', :solar_system => system1, :user_id => 'user1'
    ship2  = Manufactured::Ship.new :id => 'ship2', :user_id => 'user2'
    station1  = Manufactured::Station.new :id => 'station1', :solar_system => system1, :user_id => 'user1', :location => Motel::Location.new(:id => 5)
    station2  = Manufactured::Station.new :id => 'station2', :solar_system => system2, :location => Motel::Location.new(:id => 10)
    fleet1  = Manufactured::Fleet.new :id => 'fleet1'
    fleet2  = Manufactured::Fleet.new :id => 'fleet2'

    Manufactured::Registry.instance.create(ship1)
    Manufactured::Registry.instance.create(ship1)
    Manufactured::Registry.instance.create(ship2)
    Manufactured::Registry.instance.create(station1)
    Manufactured::Registry.instance.create(station1)
    Manufactured::Registry.instance.create(station2)
    Manufactured::Registry.instance.create(fleet1)
    Manufactured::Registry.instance.create(fleet1)
    Manufactured::Registry.instance.create(fleet2)
    Manufactured::Registry.instance.create(Object.new)

    Manufactured::Registry.instance.ships.size.should == 2
    Manufactured::Registry.instance.ships.should include(ship1)
    Manufactured::Registry.instance.ships.should include(ship2)

    Manufactured::Registry.instance.stations.size.should == 2
    Manufactured::Registry.instance.stations.should include(station1)
    Manufactured::Registry.instance.stations.should include(station2)

    Manufactured::Registry.instance.fleets.size.should == 2
    Manufactured::Registry.instance.fleets.should include(fleet1)
    Manufactured::Registry.instance.fleets.should include(fleet2)

    Manufactured::Registry.instance.children.size.should == 6

    Manufactured::Registry.instance.find(:id => 'ship1').first.should == ship1
    system_entities = Manufactured::Registry.instance.find(:parent_id => 'system1')
    system_entities.size.should == 2
    system_entities.should include(ship1)
    system_entities.should include(station1)

    user_ships = Manufactured::Registry.instance.find(:user_id => 'user1', :type => 'Manufactured::Ship')
    user_ships.size.should == 1
    user_ships.first.should == ship1

    station = Manufactured::Registry.instance.find(:location_id => 5).first
    station.should == station1
  end

  it "should permit transferring resources between entities" do
    ship  = Manufactured::Ship.new :id => 'ship1'
    station  = Manufactured::Station.new :id => 'station1'

    Manufactured::Registry.instance.create(ship)
    Manufactured::Registry.instance.create(station)

    res = Cosmos::Resource.new :type => 'metal', :name => 'gold'
    ship.add_resource res, 50

    Manufactured::Registry.instance.transfer_resource(nil, station, res, 25)
    ship.resources[res.id].should == 50
    station.resources[res.id].should be_nil

    Manufactured::Registry.instance.transfer_resource(ship, nil, res, 25)
    ship.resources[res.id].should == 50
    station.resources[res.id].should be_nil

    Manufactured::Registry.instance.transfer_resource(ship, station, res, 250)
    ship.resources[res.id].should == 50
    station.resources[res.id].should be_nil

    nres = Cosmos::Resource.new :type => 'gem', :name => 'diamond'
    Manufactured::Registry.instance.transfer_resource(ship, station, nres, 1)
    ship.resources[res.id].should == 50
    station.resources[res.id].should be_nil

    Manufactured::Registry.instance.transfer_resource(ship, station, res, 20)
    ship.resources[res.id].should == 30
    station.resources[res.id].should == 20
  end

  it "should run attack cycle" do
    Manufactured::Registry.instance.running?.should be_true

    attacker = Manufactured::Ship.new  :id => 'ship1'
    defender = Manufactured::Ship.new  :id => 'ship2'

    # 1 hit every second
    attacker.attack_rate = 1

    # need 2 hits to destroy defender
    attacker.damage_dealt = 5
    defender.hp = 10

    Manufactured::Registry.instance.create attacker
    Manufactured::Registry.instance.create defender
    Manufactured::Registry.instance.ships.should include(attacker)
    Manufactured::Registry.instance.ships.should include(defender)

    Manufactured::Registry.instance.schedule_attack :attacker => attacker, :defender => defender
    sleep 3

    Manufactured::Registry.instance.ships.should_not include(defender)

    Manufactured::Registry.instance.terminate
    Manufactured::Registry.instance.running?.should be_false
  end

  it "should run attack cycle" do
    Manufactured::Registry.instance.running?.should be_true

     ship     = Manufactured::Ship.new  :id => 'ship1'
     resource = Cosmos::Resource.new :type => 'gem', :name => 'diamond'
     source   = Cosmos::ResourceSource.new :resource => resource

     # 1 mining operation every 2 seconds
     ship.mining_rate = 0.5

     # need 2 mining operations to deplete source
     ship.mining_quantity = 5
     source.quantity = 10

    Manufactured::Registry.instance.create ship
    Manufactured::Registry.instance.ships.should include(ship)

    Manufactured::Registry.instance.schedule_mining :ship => ship, :resource_source => source
    sleep 1
    ship.mining.should be_true
    Manufactured::Registry.instance.mining_commands.size.should == 1
    sleep 2

    ship.mining.should be_false
    Manufactured::Registry.instance.mining_commands.should be_empty

    Manufactured::Registry.instance.terminate
    Manufactured::Registry.instance.running?.should be_false
  end

  it "should save registered manufactured ships and stations to io object" do
    ship1  = Manufactured::Ship.new :id => 'ship1'
    ship2  = Manufactured::Ship.new :id => 'ship2'
    station  = Manufactured::Station.new :id => 'station'
    fleet  = Manufactured::Fleet.new :id => 'fleet'

    Manufactured::Registry.instance.terminate
    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create ship2
    Manufactured::Registry.instance.create station
    Manufactured::Registry.instance.create fleet
    Manufactured::Registry.instance.children.size.should == 4

    sio = StringIO.new
    Manufactured::Registry.instance.save_state(sio)
    s = sio.string

    s.should include('"id":"ship1"')
    s.should include('"id":"ship2"')
    s.should include('"id":"station"')
    s.should_not include('"id":"fleet"')
  end

  it "should restore registered manufactured entities from io object" do
    s = '{"data":{"type":null,"docked_at":null,"solar_system":null,"user_id":null,"size":null,"id":"ship1","location":{"data":{"remote_queue":null,"y":0,"parent_id":null,"x":0,"restrict_view":true,"z":0,"restrict_modify":true,"id":null,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"}},"json_class":"Motel::Location"}},"json_class":"Manufactured::Ship"}' + "\n" +
        '{"data":{"type":null,"docked_at":null,"solar_system":null,"user_id":null,"size":null,"id":"ship2","location":{"data":{"remote_queue":null,"y":0,"parent_id":null,"x":0,"restrict_view":true,"z":0,"restrict_modify":true,"id":null,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"}},"json_class":"Motel::Location"}},"json_class":"Manufactured::Ship"}' + "\n" +
        '{"data":{"type":null,"solar_system":null,"user_id":null,"size":null,"id":"station","location":{"data":{"remote_queue":null,"y":0,"parent_id":null,"x":0,"restrict_view":true,"z":0,"restrict_modify":true,"id":null,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"}},"json_class":"Motel::Location"}},"json_class":"Manufactured::Station"}'
    a = s.collect { |i| i }

    Manufactured::Registry.instance.restore_state(a)
    Manufactured::Registry.instance.children.size.should == 3

    ids = Manufactured::Registry.instance.children.collect { |c| c.id }
    ids.should include("ship1")
    ids.should include("ship2")
    ids.should include("station")
  end

end
