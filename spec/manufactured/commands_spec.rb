# Commands module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'timecop'

describe Manufactured::AttackCommand do

  after(:all) do
    Timecop.return
  end

  it "should run attack cycle between ships" do
     attacker = Manufactured::Ship.new  :id => 'ship1', :type => :corvette, :user_id => 'user1'
     defender = Manufactured::Ship.new  :id => 'ship2', :user_id => 'user2'

     sys1  = Cosmos::SolarSystem.new :name => 'sys1'
     attacker.parent = sys1
     defender.parent = sys1

     # 1 hit every 2 seconds
     attacker.attack_rate = 0.5

     # need 2 hits to destroy defender
     attacker.damage_dealt = 5
     defender.hp = 10

     before_hook = lambda { |c| }

     cmd = Manufactured::AttackCommand.new :attacker => attacker, :defender => defender, :before => before_hook

     cmd.attacker.should == attacker
     cmd.defender.should == defender
     cmd.hooks[:before].size.should == 1
     cmd.hooks[:before].first.should == before_hook
     cmd.id.should == attacker.id
     cmd.remove?.should be_false
     cmd.attackable?.should be_true

     cmd.attack!
     cmd.attackable?.should be_false
     defender.hp.should == 5
     cmd.remove?.should be_false

     Timecop.travel(2)
     cmd.attackable?.should be_true
     cmd.attack!
     defender.hp.should == 0
     cmd.remove?.should be_true
  end

  it "should invoke attack cycle callbacks" do
     attacker = Manufactured::Ship.new  :id => 'ship1', :type => :bomber, :user_id => 'user1'
     defender = Manufactured::Ship.new  :id => 'ship2', :user_id => 'user2'

     sys1  = Cosmos::SolarSystem.new :name => 'sys1'
     attacker.parent = sys1
     defender.parent = sys1

     # 1 hit every second
     attacker.attack_rate = 1

     # need 2 hits to destroy defender
     attacker.damage_dealt = 5
     defender.hp = 10

     # setup callbacks
     attacked_invoked = 0
     defended_invoked = 0
     attacked_stopped_invoked = false
     defended_stopped_invoked = false
     destroyed_invoked = false
     attacker.notification_callbacks << Manufactured::Callback.new('attacked')      { attacked_invoked += 1 }
     attacker.notification_callbacks << Manufactured::Callback.new('attacked_stop') { attacked_stopped_invoked = true }
     defender.notification_callbacks << Manufactured::Callback.new('defended')      { defended_invoked += 1 }
     defender.notification_callbacks << Manufactured::Callback.new('destroyed')     { destroyed_invoked = true }
     defender.notification_callbacks << Manufactured::Callback.new('defended_stop') { defended_stopped_invoked = true }

     cmd = Manufactured::AttackCommand.new :attacker => attacker, :defender => defender

     cmd.attack!
     attacked_invoked.should == 1
     attacked_stopped_invoked.should be_false
     defended_invoked.should == 1
     destroyed_invoked.should be_false
     defended_stopped_invoked.should be_false
     cmd.remove?.should be_false

     cmd.attack!
     attacked_invoked.should == 2
     attacked_stopped_invoked.should be_true
     defended_invoked.should == 2
     destroyed_invoked.should be_true
     defended_stopped_invoked.should be_true
     cmd.remove?.should be_true
  end

  it "should terminate attack cycle and invoke callbacks if targets are too far apart" do
     attacker = Manufactured::Ship.new  :id => 'ship1', :user_id => 'user1', :type => :corvette, :location => Motel::Location.new(:x => 0, :y => 0, :z => 0)
     defender = Manufactured::Ship.new  :id => 'ship2', :user_id => 'user2', :location => Motel::Location.new(:x => 90,:y => 0, :z => 0)

     sys1  = Cosmos::SolarSystem.new :name => 'sys1'
     attacker.parent = sys1
     defender.parent = sys1

     attacker.attack_rate = 1
     attacker.damage_dealt = 5
     defender.hp = 100

     # setup callbacks
     attacked_invoked = 0
     defended_invoked = 0
     attacked_stopped_invoked = false
     defended_stopped_invoked = false
     destroyed_invoked = false
     attacker.notification_callbacks << Manufactured::Callback.new('attacked')      { attacked_invoked += 1 }
     attacker.notification_callbacks << Manufactured::Callback.new('attacked_stop') { attacked_stopped_invoked = true }
     defender.notification_callbacks << Manufactured::Callback.new('defended')      { defended_invoked += 1 }
     defender.notification_callbacks << Manufactured::Callback.new('destroyed')     { destroyed_invoked = true }
     defender.notification_callbacks << Manufactured::Callback.new('defended_stop') { defended_stopped_invoked = true }

     cmd = Manufactured::AttackCommand.new :attacker => attacker, :defender => defender

     cmd.attack!
     attacked_invoked.should == 1
     attacked_stopped_invoked.should be_false
     defended_invoked.should == 1
     destroyed_invoked.should be_false
     defended_stopped_invoked.should be_false
     cmd.remove?.should be_false
     defender.hp.should == 95

     defender.location.x = 200

     cmd.attack!
     attacked_invoked.should == 1
     attacked_stopped_invoked.should be_true
     defended_invoked.should == 1
     destroyed_invoked.should be_false
     defended_stopped_invoked.should be_true
     cmd.remove?.should be_true
     defender.hp.should == 95
  end

end

describe Manufactured::MiningCommand do
  it "should run mining cycle" do
     sys1  = Cosmos::SolarSystem.new :name => "sys1", :location => Motel::Location.new(:id => 1)
     ship     = Manufactured::Ship.new  :id => 'ship1', :solar_system => sys1, :type => :mining
     entity   = Cosmos::Asteroid.new :name => 'ast1', :solar_system => sys1
     resource = Cosmos::Resource.new :type => 'gem', :name => 'diamond'
     source   = Cosmos::ResourceSource.new :resource => resource, :entity => entity

     ship.parent = sys1
     sys1.add_child(entity)

     # 1 mining operations every second
     ship.mining_rate = 1

     # need 3 mining operations to deplete source
     ship.mining_quantity = 5
     source.quantity = 10.3

     before_hook = lambda { |c| }

     cmd = Manufactured::MiningCommand.new :ship => ship, :resource_source => source, :before => before_hook

     cmd.ship.should == ship
     cmd.hooks[:before].size.should == 1
     cmd.hooks[:before].first.should == before_hook
     cmd.id.should == ship.id
     cmd.resource_source.should == source
     cmd.remove?.should be_false
     cmd.minable?.should be_true

     cmd.mine!
     cmd.minable?.should be_false
     ship.resources.size.should == 1
     ship.resources[resource.id].should == 5
     source.quantity.round_to(1).should == 5.3
     cmd.remove?.should be_false

     Timecop.travel(1)
     cmd.minable?.should be_true
     cmd.mine!
     ship.resources[resource.id].should == 10
     source.quantity.round_to(1).should == 0.3
     cmd.remove?.should be_false

     Timecop.travel(1)
     cmd.minable?.should be_true
     cmd.mine!
     ship.resources[resource.id].should == 10.3
     source.quantity.should == 0

     cmd.mine!
     cmd.remove?.should be_true
  end

  it "should invoke mining cycle callbacks" do
     sys1  = Cosmos::SolarSystem.new :name => "sys1", :location => Motel::Location.new(:id => 1)
     ship     = Manufactured::Ship.new  :id => 'ship1', :solar_system => sys1, :type => :mining, :location => Motel::Location.new(:x => 50, :y => 0, :z => 0)
     entity   = Cosmos::Asteroid.new :name => 'ast1', :solar_system => sys1, :location => Motel::Location.new(:x => 0, :y => 0, :z => 0)
     resource = Cosmos::Resource.new :type => 'gem', :name => 'diamond'
     source   = Cosmos::ResourceSource.new :resource => resource, :entity => entity

     ship.parent = sys1
     sys1.add_child entity

     # 1 mining operation every second
     ship.mining_rate = 1

     # need 2 mining operations to deplete source
     ship.mining_quantity = 5
     source.quantity = 10

     # setup callbacks
     stopped_reason = nil
     times_resources_collected = 0
     resources_depleted_invoked = false
     ship.notification_callbacks << Manufactured::Callback.new('resource_collected') { times_resources_collected += 1 }
     ship.notification_callbacks << Manufactured::Callback.new('resource_depleted')  { resources_depleted_invoked = true }
     ship.notification_callbacks << Manufactured::Callback.new('mining_stopped') { |cb, reason, nship, nresource|  stopped_reason = reason}

     cmd = Manufactured::MiningCommand.new :ship => ship, :resource_source => source

     cmd.mine!
     times_resources_collected.should == 1
     resources_depleted_invoked.should == false
     stopped_reason.should be_nil
     cmd.remove?.should be_false
     ship.resources[resource.id].should == 5
     source.quantity.should == 5

     cmd.mine!
     times_resources_collected.should == 2

     cmd.mine!
     resources_depleted_invoked.should == true
     stopped_reason.should == "resource_depleted"
     cmd.remove?.should be_true
     ship.resources[resource.id].should == 10
     source.quantity.should == 0

     source.quantity = 50
     stopped_reason = nil
     times_resources_collected = 0
     resources_depleted_invoked = false
     ship.add_resource("metal-alloy", 90)
     cmd.instance_variable_set(:@remove, false)

     cmd.mine!
     times_resources_collected.should == 0
     resources_depleted_invoked.should == false
     stopped_reason.should == "ship_cargo_full"
     cmd.remove?.should be_true
     ship.resources[resource.id].should == 10
     ship.resources['metal-alloy'].should == 90
     ship.cargo_quantity.should == 100
     source.quantity.should == 50

     stopped_reason = nil
     times_resources_collected = 0
     resources_depleted_invoked = false
     ship.remove_resource("metal-alloy", 90)
     cmd.instance_variable_set(:@remove, false)
     ship.location.x = 120

     cmd.mine!
     times_resources_collected.should == 0
     resources_depleted_invoked.should == false
     stopped_reason.should == "mining_distance_exceeded"
     cmd.remove?.should be_true
     ship.resources[resource.id].should == 10
     source.quantity.should == 50
  end

  it "should terminate mining cycle and invoke callbacks if ship can no longer mine resource source" do
     sys1  = Cosmos::SolarSystem.new :name => "sys1", :location => Motel::Location.new(:id => 1)
     sys2  = Cosmos::SolarSystem.new :name => "sys2", :location => Motel::Location.new(:id => 2)
     ship     = Manufactured::Ship.new  :id => 'ship1', :type => :mining, :solar_system => sys1, :location => Motel::Location.new(:x => 50, :y => 0, :z => 0)
     stat     = Manufactured::Station.new :id => 'stat1', :solar_system => sys1
     entity   = Cosmos::Asteroid.new :name => 'ast1', :solar_system => sys1, :location => Motel::Location.new(:x => 0, :y => 0, :z => 0)
     resource = Cosmos::Resource.new :type => 'gem', :name => 'diamond'
     source   = Cosmos::ResourceSource.new :resource => resource, :entity => entity

     ship.parent = sys1
     sys1.add_child entity

     # 1 mining operation every second
     ship.mining_rate = 1

     # need 2 mining operations to deplete source
     ship.mining_quantity = 5
     source.quantity = 20

     # setup callbacks
     stopped_reason = nil
     ship.notification_callbacks << Manufactured::Callback.new('mining_stopped') { |cb, reason, nship, nresource|  stopped_reason = reason}

     cmd = Manufactured::MiningCommand.new :ship => ship, :resource_source => source
     cmd.mine!
     stopped_reason.should be_nil
     cmd.remove?.should be_false

     ship.parent = sys2
     ship.location.parent = sys2.location
     cmd.mine!
     cmd.remove?.should be_true
     stopped_reason.should == 'mining_distance_exceeded'
     stopped_reason = nil
     cmd.instance_variable_set(:@remove, false)
     ship.parent = sys1
     ship.location.parent = sys1.location

     ship.location.x = 500
     cmd.mine!
     cmd.remove?.should be_true
     stopped_reason.should == 'mining_distance_exceeded'
     stopped_reason = nil
     cmd.instance_variable_set(:@remove, false)
     ship.location.x = 0

     ship.resources.clear
     ship.add_resource('metal-alloy', ship.cargo_capacity-1)
     cmd.mine!
     cmd.remove?.should be_true
     stopped_reason.should == 'ship_cargo_full'
     stopped_reason = nil
     cmd.instance_variable_set(:@remove, false)
     ship.remove_resource('metal-alloy', ship.cargo_capacity-1)

     ship.dock_at(stat)
     cmd.mine!
     cmd.remove?.should be_true
     stopped_reason.should == 'ship_docked'
     stopped_reason = nil
     cmd.instance_variable_set(:@remove, false)
     ship.undock

     source.quantity = 0
     cmd.mine!
     cmd.remove?.should be_true
     stopped_reason.should == 'resource_depleted'
     stopped_reason = nil
     cmd.instance_variable_set(:@remove, false)
     source.quantity = 20

     cmd.mine!
     stopped_reason.should be_nil
     cmd.remove?.should be_false
  end

end
