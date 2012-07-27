# Fleet module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Manufactured::Fleet do

  it "should successfully accept and set fleet params" do
     solar_system = Cosmos::SolarSystem.new :name => 'system44'
     ship1 = Manufactured::Ship.new  :id => 'ship1', :solar_system => solar_system
     ship2 = Manufactured::Ship.new  :id => 'ship2'
     fleet = Manufactured::Fleet.new :id => 'fleet1', :user_id => 5,
                                     :ships => [ship1, ship2]
                                   
     fleet.id.should == 'fleet1'
     fleet.user_id.should == 5
     fleet.location.should be_nil
     fleet.ships.size.should == 2
     fleet.ships.should include(ship1)
     fleet.ships.should include(ship2)

     fleet.solar_system.name.should == 'system44'
     fleet.parent.name.should == 'system44'
  end

  it "should verify validity of fleet" do
    fleet = Manufactured::Fleet.new :id => 'station1', :user_id => 'tu'
    fleet.valid?.should be_true

    fleet.id = nil
    fleet.valid?.should be_false
    fleet.id = 'station1'

    fleet.user_id = nil
    fleet.valid?.should be_false
    fleet.user_id = 'tu'

    fleet.ships << nil
    fleet.valid?.should be_false
    fleet.ships.clear
    fleet.ships << Manufactured::Ship.new

    fleet.ship_ids << nil
    fleet.valid?.should be_false
    fleet.ship_ids.clear
    fleet.ship_ids << "101"

    fleet.valid?.should be_true
  end


  it "should be convertable to json" do
    solar_system = Cosmos::SolarSystem.new :name => 'system44'
    ship1 = Manufactured::Ship.new  :id => 'ship1', :solar_system => solar_system
    ship2 = Manufactured::Ship.new  :id => 'ship2'
    location= Motel::Location.new :id => 20, :y => -15
    s = Manufactured::Fleet.new(:id => 'fleet42', :user_id => 420,
                                :ships => [ship1, ship2])

    j = s.to_json
    j.should include('"json_class":"Manufactured::Fleet"')
    j.should include('"id":"fleet42"')
    j.should include('"user_id":420')
    j.should include('"solar_system":"system44"')
    j.should include('"ship_ids":["ship1","ship2"]')
  end

  it "should be convertable from json" do
    j = '{"data":{"user_id":420,"solar_system":"system44","id":"fleet42","ship_ids":["ship1","ship2"]},"json_class":"Manufactured::Fleet"}'
    s = JSON.parse(j)

    s.class.should == Manufactured::Fleet
    s.id.should == "fleet42"
    s.user_id.should == 420
  end

end
