# Commands module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Manufactured::AttackCommand do

  it "should run attack cycle between ships" do
     attacker = Manufactured::Ship.new  :id => 'ship1'
     defender = Manufactured::Ship.new  :id => 'ship2'

     # 1 hit every 2 seconds
     attacker.attack_rate = 0.5

     # need 2 hits to destroy defender
     attacker.damage_dealt = 5
     defender.hp = 10

     cmd = Manufactured::AttackCommand.new :attacker => attacker, :defender => defender

     cmd.attacker.should == attacker
     cmd.defender.should == defender
     cmd.remove?.should be_false
     cmd.attackable?.should be_true

     cmd.attack!
     cmd.attackable?.should be_false
     defender.hp.should == 5
     cmd.remove?.should be_false

     sleep 2
     cmd.attackable?.should be_true
     cmd.attack!
     defender.hp.should == 0
     cmd.remove?.should be_true
  end

  it "should invoke attack cycle callbacks" do
     attacker = Manufactured::Ship.new  :id => 'ship1'
     defender = Manufactured::Ship.new  :id => 'ship2'

     # 1 hit every second
     attacker.attack_rate = 1

     # need 2 hits to destroy defender
     attacker.damage_dealt = 5
     defender.hp = 10

     # setup callbacks
     attack_invoked = 0
     destroyed_invoked = false
     attack_stopped_invoked = false
     defender.notification_callbacks << Manufactured::Callback.new('attacked')      { attack_invoked += 1 }
     defender.notification_callbacks << Manufactured::Callback.new('destroyed')     { destroyed_invoked = true }
     defender.notification_callbacks << Manufactured::Callback.new('attacked_stop') { attack_stopped_invoked = true }

     cmd = Manufactured::AttackCommand.new :attacker => attacker, :defender => defender

     cmd.attack!
     attack_invoked.should == 1
     destroyed_invoked.should be_false
     attack_stopped_invoked.should be_false

     sleep 1
     cmd.attack!
     attack_invoked.should == 2
     destroyed_invoked.should be_true
     attack_stopped_invoked.should be_true
  end

end

describe Manufactured::MiningCommand do
  it "should run mining cycle" do
     ship     = Manufactured::Ship.new  :id => 'ship1'
     resource = Cosmos::Resource.new :type => 'gem', :name => 'diamond'
     source   = Cosmos::ResourceSource.new :resource => resource

     # 1 mining operation every 2 seconds
     ship.mining_rate = 0.5

     # need 2 mining operations to deplete source
     ship.mining_quantity = 5
     source.quantity = 10

     cmd = Manufactured::MiningCommand.new :ship => ship, :resource_source => source

     cmd.ship.should == ship
     cmd.resource_source.should == source
     cmd.remove?.should be_false
     cmd.minable?.should be_true

     cmd.mine!
     cmd.minable?.should be_false
     ship.resources.size.should == 1
     ship.resources[resource.id].should == 5
     source.quantity.should == 5
     cmd.remove?.should be_false

     sleep 2
     cmd.minable?.should be_true
     cmd.mine!
     ship.resources[resource.id].should == 10
     source.quantity.should == 0
     cmd.remove?.should be_true
  end

end
