# registry module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'stringio'

describe Manufactured::Registry do

  before(:each) do
    Manufactured::Registry.instance.init
  end

  after(:each) do
    Manufactured::Registry.instance.terminate
  end

  it "should provide access to valid manufactured entity types" do
    valid_types = Manufactured::Registry.instance.entity_types
    valid_types.should include(Manufactured::Ship)
    valid_types.should include(Manufactured::Station)
    valid_types.should include(Manufactured::Fleet)
    valid_types.should_not include(Integer)
  end

  it "should raise error if adding invalid child entity" do
    sys = Cosmos::SolarSystem.new :name => 'sys1'
    ship1   = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :solar_system => sys
    ship1a  = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :solar_system => sys
    ship2   = Manufactured::Ship.new :id => 10101
    station1   = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :solar_system => nil

    # valid
    lambda {
      Manufactured::Registry.instance.create ship1
    }.should_not raise_error

    # duplicate
    lambda {
      Manufactured::Registry.instance.create ship1
    }.should raise_error(ArgumentError)

    # duplicate id
    lambda {
      Manufactured::Registry.instance.create ship1a
    }.should raise_error(ArgumentError)

    # not valid
    lambda {
      Manufactured::Registry.instance.create ship2
    }.should raise_error(ArgumentError)

    # not valid
    lambda {
      Manufactured::Registry.instance.create station1
    }.should raise_error(ArgumentError)

    # wrong type
    lambda {
      Manufactured::Registry.instance.create 111
    }.should raise_error(ArgumentError)

    Manufactured::Registry.instance.ships.size.should == 1
    Manufactured::Registry.instance.stations.size.should == 0
    Manufactured::Registry.instance.fleets.size.should == 0
  end

  it "provide acceses to managed manufactured entities" do
    Manufactured::Registry.instance.ships.size.should == 0
    Manufactured::Registry.instance.stations.size.should == 0
    Manufactured::Registry.instance.fleets.size.should == 0


    system1 = Cosmos::SolarSystem.new :name => 'system1'
    system2 = Cosmos::SolarSystem.new :name => 'system2'
    ship1  = Manufactured::Ship.new :id => 'ship1', :solar_system => system1, :user_id => 'user1'
    ship2  = Manufactured::Ship.new :id => 'ship2', :solar_system => system2, :user_id => 'user2'
    station1  = Manufactured::Station.new :id => 'station1', :solar_system => system1, :user_id => 'user1', :location => Motel::Location.new(:id => 5)
    station2  = Manufactured::Station.new :id => 'station2', :solar_system => system2, :user_id => 'user1', :location => Motel::Location.new(:id => 10)
    fleet1  = Manufactured::Fleet.new :id => 'fleet1', :user_id => 'user1'
    fleet2  = Manufactured::Fleet.new :id => 'fleet2', :user_id => 'user1'

    Manufactured::Registry.instance.create(ship1)
    begin ; Manufactured::Registry.instance.create(ship1) ; rescue Exception => e ; end
    Manufactured::Registry.instance.create(ship2)
    Manufactured::Registry.instance.create(station1)
    begin ; Manufactured::Registry.instance.create(station1) ; rescue Exception => e ; end
    Manufactured::Registry.instance.create(station2)
    Manufactured::Registry.instance.create(fleet1)
    begin ; Manufactured::Registry.instance.create(fleet1) ; rescue Exception => e ; end
    Manufactured::Registry.instance.create(fleet2)
    begin ; Manufactured::Registry.instance.create(Object.new) ; rescue Exception => e ; end

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

  it "provide access to managed ship graveyard" do
    system1 = Cosmos::SolarSystem.new :name => 'system1'
    ship1   = Manufactured::Ship.new :id => 'ship1',
                           :solar_system => system1,
                                 :user_id => 'user1'

    Manufactured::Registry.instance.graveyard.size.should == 0
    Manufactured::Registry.instance.instance_variable_get(:@ship_graveyard) << ship1

    Manufactured::Registry.instance.graveyard.size.should == 1
    Manufactured::Registry.instance.graveyard.first.should == ship1

    rship = Manufactured::Registry.instance.find(:id => 'ship1')
    rship.should be_empty

    rship = Manufactured::Registry.instance.find(:id => 'ship1', :include_graveyard => false)
    rship.should be_empty

    rship = Manufactured::Registry.instance.find(:id => 'ship1', :include_graveyard => true)
    rship.size.should  == 1
    rship.first.should == ship1
  end

  it "provide acceses to managed loot" do
    system1 = Cosmos::SolarSystem.new :name => 'system1'
    loot1   = Manufactured::Loot.new :id => 'loot1', :resources => {'metal-steel' => 50}
    loot2   = Manufactured::Loot.new :id => 'loot2', :resources => {'metal-steel' => 50}

    Manufactured::Registry.instance.loot.size.should == 0
    Manufactured::Registry.instance.set_loot(loot1)

    Manufactured::Registry.instance.loot.size.should == 1
    Manufactured::Registry.instance.loot.first.should == loot1

    Manufactured::Registry.instance.set_loot(loot1)
    Manufactured::Registry.instance.loot.size.should == 1

    Manufactured::Registry.instance.set_loot(loot2)
    Manufactured::Registry.instance.loot.size.should == 2

    loot2.remove_resource('metal-steel', 50)
    Manufactured::Registry.instance.set_loot(loot2)
    Manufactured::Registry.instance.loot.size.should == 1
    Manufactured::Registry.instance.loot.first.should == loot1

    lloot1 = Manufactured::Registry.instance.find(:id => 'loot1')
    lloot1.should be_empty

    lloot1 = Manufactured::Registry.instance.find(:id => 'loot1', :include_loot => false)
    lloot1.should be_empty

    lloot1 = Manufactured::Registry.instance.find(:id => 'loot1', :include_loot => true)
    lloot1.size.should  == 1
    lloot1.first.should == loot1
  end

  it "should permit transferring resources between entities" do
    sys   = Cosmos::SolarSystem.new
    ship  = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :solar_system => sys
    station  = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :solar_system => sys

    Manufactured::Registry.instance.create(ship)
    Manufactured::Registry.instance.create(station)

    res = Cosmos::Resource.new :type => 'metal', :name => 'gold'
    ship.add_resource res.id, 50

    Manufactured::Registry.instance.transfer_resource(nil, station, res.id, 25)
    ship.resources[res.id].should == 50
    station.resources[res.id].should be_nil

    Manufactured::Registry.instance.transfer_resource(ship, nil, res.id, 25)
    ship.resources[res.id].should == 50
    station.resources[res.id].should be_nil

    Manufactured::Registry.instance.transfer_resource(ship, station, res.id, 250)
    ship.resources[res.id].should == 50
    station.resources[res.id].should be_nil

    nres = Cosmos::Resource.new :type => 'gem', :name => 'diamond'
    Manufactured::Registry.instance.transfer_resource(ship, station, nres.id, 1)
    ship.resources[res.id].should == 50
    station.resources[res.id].should be_nil

    Manufactured::Registry.instance.transfer_resource(ship, station, res.id, 20)
    ship.resources[res.id].should == 30
    station.resources[res.id].should == 20

    res2 = Cosmos::Resource.new :type => 'metal', :name => 'silver'
    station.add_resource res2.id, 500

    # would exceed cargo capacity:
    Manufactured::Registry.instance.transfer_resource(station, ship, res2.id, 200)
    ship.resources[res2.id].should be_nil
    station.resources[res2.id].should == 500
  end

  it "should run attack cycle" do
    Manufactured::Registry.instance.running?.should be_true

    sys = Cosmos::SolarSystem.new
    attacker = Manufactured::Ship.new  :id => 'ship1', :solar_system => sys, :user_id => 'user1', :type => :battlecruiser
    defender = Manufactured::Ship.new  :id => 'ship2', :solar_system => sys, :user_id => 'user2'

    # 1 hit every second
    attacker.attack_rate = 1

    # need 2 hits to destroy defender
    attacker.damage_dealt = 5
    defender.hp = 10

    Manufactured::Registry.instance.create attacker
    Manufactured::Registry.instance.create defender
    Manufactured::Registry.instance.ships.should include(attacker)
    Manufactured::Registry.instance.ships.should include(defender)
    Manufactured::Registry.instance.ship_graveyard.size.should == 0

    before_hook_called = false
    before_hook = lambda { |cmd| before_hook_called = true }

    Manufactured::Registry.instance.schedule_attack :attacker => attacker, :defender => defender, :before => before_hook
    sleep 1
    attacker.attacking?.should be_true
    sleep 2
    attacker.attacking?.should be_false

    Manufactured::Registry.instance.ships.should_not include(defender)
    Manufactured::Registry.instance.ship_graveyard.should include(defender)
    before_hook_called.should be_true

    Manufactured::Registry.instance.terminate
    Manufactured::Registry.instance.running?.should be_false
  end

  it "should replace duplicate attack commands" do
    Manufactured::Registry.instance.running?.should be_true

    sys   = Cosmos::SolarSystem.new
    attacker = Manufactured::Ship.new  :id => 'ship1', :solar_system => sys, :user_id => 'user1'
    defender1 = Manufactured::Ship.new  :id => 'ship2', :solar_system => sys, :user_id => 'user1'
    defender2 = Manufactured::Ship.new  :id => 'ship3', :solar_system => sys, :user_id => 'user1'

    attacker.attack_rate = 1
    attacker.damage_dealt = 5
    defender1.hp = 10
    defender2.hp = 10

    Manufactured::Registry.instance.create attacker
    Manufactured::Registry.instance.create defender1
    Manufactured::Registry.instance.create defender2
    Manufactured::Registry.instance.schedule_attack :attacker => attacker, :defender => defender1

    Manufactured::Registry.instance.attack_commands.size.should == 1
    Manufactured::Registry.instance.attack_commands[attacker.id].defender.id.should == defender1.id

    Manufactured::Registry.instance.schedule_attack :attacker => attacker, :defender => defender2
    Manufactured::Registry.instance.attack_commands.size.should == 1
    Manufactured::Registry.instance.attack_commands[attacker.id].defender.id.should == defender2.id
  end

  it "should run mining cycle" do
    Manufactured::Registry.instance.running?.should be_true

     sys   = Cosmos::SolarSystem.new
     ship     = Manufactured::Ship.new  :id => 'ship1', :solar_system => sys, :user_id => 'user1', :type => :mining
     entity  = Cosmos::Asteroid.new :name => 'ast1', :solar_system => sys
     resource = Cosmos::Resource.new :type => 'gem', :name => 'diamond'
     source   = Cosmos::ResourceSource.new :resource => resource, :entity => entity

     sys.add_child entity

     # 1 mining operation every second
     ship.mining_rate = 1

     # need 2 mining operations to deplete source
     ship.mining_quantity = 5
     source.quantity = 10

    Manufactured::Registry.instance.create ship
    Manufactured::Registry.instance.ships.should include(ship)

    before_hook_called = false
    before_hook = lambda { |cmd| before_hook_called = true }

    Manufactured::Registry.instance.schedule_mining :ship => ship, :resource_source => source, :before => before_hook
    sleep 1
    ship.mining?.should be_true
    Manufactured::Registry.instance.mining_commands.size.should == 1
    before_hook_called.should be_true
    sleep 2

    ship.mining?.should be_false
    Manufactured::Registry.instance.mining_commands.should be_empty

    Manufactured::Registry.instance.terminate
    Manufactured::Registry.instance.running?.should be_false
  end

  it "should replace duplicate mining commands" do
    Manufactured::Registry.instance.running?.should be_true

    sys   = Cosmos::SolarSystem.new
    ship     = Manufactured::Ship.new  :id => 'ship1', :solar_system => sys, :user_id => 'user1'
    entity1  = Cosmos::Asteroid.new :name => 'ast1', :solar_system => sys
    resource1 = Cosmos::Resource.new :type => 'gem', :name => 'diamond'
    source1   = Cosmos::ResourceSource.new :resource => resource1, :entity => entity1
    entity2  = Cosmos::Asteroid.new :name => 'ast2', :solar_system => sys
    resource2 = Cosmos::Resource.new :type => 'gem', :name => 'ruby'
    source2   = Cosmos::ResourceSource.new :resource => resource2, :entity => entity2

    ship.mining_rate = 0.5
    ship.mining_quantity = 5
    source1.quantity = 10
    source2.quantity = 10

    Manufactured::Registry.instance.create ship
    Manufactured::Registry.instance.schedule_mining :ship => ship, :resource_source => source1

    Manufactured::Registry.instance.mining_commands.size.should == 1
    Manufactured::Registry.instance.mining_commands[ship.id].resource_source.id.should == source1.id

    Manufactured::Registry.instance.schedule_mining :ship => ship, :resource_source => source2
    Manufactured::Registry.instance.mining_commands.size.should == 1
    Manufactured::Registry.instance.mining_commands[ship.id].resource_source.id.should == source2.id
  end

  it "should run the construction cycle" do
    Manufactured::Registry.instance.running?.should be_true

    sys      = Cosmos::SolarSystem.new
    station  = Manufactured::Station.new  :id => 'station1', :solar_system => sys, :user_id => 'user1', :type => :mining
    ship     = Manufactured::Ship.new     :id => 'ship1',    :solar_system => sys, :user_id => 'user1', :type => :mining

    Manufactured::Registry.instance.create station
    Manufactured::Registry.instance.create ship

    before_hook_called = false
    before_hook = lambda { |cmd| before_hook_called = true }

    Manufactured::Registry.instance.schedule_construction :station => station, :entity => ship, :before => before_hook
    sleep 1
    Manufactured::Registry.instance.construction_commands.size.should == 1
    before_hook_called.should be_true
    sleep 5
    Manufactured::Registry.instance.construction_commands.size.should == 0

    Manufactured::Registry.instance.terminate
    Manufactured::Registry.instance.running?.should be_false
  end

  #it "should replace duplicate construction commands" do
  #end

  it "should save registered manufactured ships and stations to io object" do
    sys    = Cosmos::SolarSystem.new
    ship1  = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :solar_system => sys
    ship2  = Manufactured::Ship.new :id => 'ship2', :user_id => 'user1', :solar_system => sys
    ship3  = Manufactured::Ship.new :id => 'ship3', :user_id => 'user1', :solar_system => sys
    station  = Manufactured::Station.new :id => 'station', :user_id => 'user1', :solar_system => sys
    fleet  = Manufactured::Fleet.new :id => 'fleet', :user_id => 'user1', :solar_system => sys

    Manufactured::Registry.instance.terminate
    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create ship2
    Manufactured::Registry.instance.create station
    Manufactured::Registry.instance.create fleet
    Manufactured::Registry.instance.children.size.should == 4

    ship3.instance_variable_set(:@hp, 0)
    Manufactured::Registry.instance.instance_variable_get(:@ship_graveyard) << ship3
    Manufactured::Registry.instance.graveyard.size.should == 1

    sio = StringIO.new
    Manufactured::Registry.instance.save_state(sio)
    s = sio.string

    s.should include('"id":"ship1"')
    s.should include('"id":"ship2"')
    s.should include('"id":"ship3"')
    s.should include('"id":"station"')
    s.should_not include('"id":"fleet"')
  end

  it "should restore registered manufactured entities from io object" do
    s = '{"data":{"type":"mining","user_id":"user1","solar_system":{"data":{"star":null,"planets":[],"background":"system4","jump_gates":[],"remote_queue":null,"location":{"data":{"restrict_view":true,"parent_id":null,"restrict_modify":true,"y":0,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"movement_callbacks":[],"children":[],"z":0,"proximity_callbacks":[],"id":null,"x":0},"json_class":"Motel::Location"},"asteroids":[],"name":null},"json_class":"Cosmos::SolarSystem"},"location":{"data":{"restrict_view":true,"parent_id":null,"restrict_modify":true,"y":0,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"movement_callbacks":[],"children":[],"z":0,"proximity_callbacks":[],"id":null,"x":0},"json_class":"Motel::Location"},"docked_at":null,"size":25,"notifications":[],"id":"ship1","resources":{}},"json_class":"Manufactured::Ship"}' + "\n" +
        '{"data":{"type":"exploration","user_id":"user1","solar_system":{"data":{"star":null,"planets":[],"background":"system4","jump_gates":[],"remote_queue":null,"location":{"data":{"restrict_view":true,"parent_id":null,"restrict_modify":true,"y":0,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"movement_callbacks":[],"children":[],"z":0,"proximity_callbacks":[],"id":null,"x":0},"json_class":"Motel::Location"},"asteroids":[],"name":null},"json_class":"Cosmos::SolarSystem"},"location":{"data":{"restrict_view":true,"parent_id":null,"restrict_modify":true,"y":0,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"movement_callbacks":[],"children":[],"z":0,"proximity_callbacks":[],"id":null,"x":0},"json_class":"Motel::Location"},"docked_at":null,"size":23,"notifications":[],"id":"ship2","resources":{}},"json_class":"Manufactured::Ship"}' + "\n" +
        '{"data":{"type":"exploration","user_id":"user1","solar_system":{"data":{"star":null,"planets":[],"background":"system4","jump_gates":[],"remote_queue":null,"location":{"data":{"restrict_view":true,"parent_id":null,"restrict_modify":true,"y":0,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"movement_callbacks":[],"children":[],"z":0,"proximity_callbacks":[],"id":null,"x":0},"json_class":"Motel::Location"},"asteroids":[],"name":null},"json_class":"Cosmos::SolarSystem"},"location":{"data":{"restrict_view":true,"parent_id":null,"restrict_modify":true,"y":0,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"movement_callbacks":[],"children":[],"z":0,"proximity_callbacks":[],"id":null,"x":0},"json_class":"Motel::Location"},"size":20,"id":"station","resources":{}},"json_class":"Manufactured::Station"}' + "\n" +
        '{"json_class":"Manufactured::Ship","data":{"id":"ship3","user_id":"user1","type":"battlecruiser","size":35,"hp":0,"attack_distance":100,"mining_distance":100,"docked_at":null,"attacking":null,"mining":null,"location":{"json_class":"Motel::Location","data":{"id":null,"x":0,"y":0,"z":0,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"movement_callbacks":[],"proximity_callbacks":[]}},"system_name":null,"resources":{},"notifications":[]}}' + "\n"
    a = s.split "\n"

    Manufactured::Registry.instance.restore_state(a)
    Manufactured::Registry.instance.children.size.should == 3

    ids = Manufactured::Registry.instance.children.collect { |c| c.id }
    ids.should include("ship1")
    ids.should include("ship2")
    ids.should include("station")

    gids = Manufactured::Registry.instance.graveyard.collect { |c| c.id }
    gids.should include("ship3")
  end

end
