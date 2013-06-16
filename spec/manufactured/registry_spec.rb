# registry module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/registry'

module Manufactured
describe Registry do
  [:ship, :station, :loot].each { |e|
    it "provides access to #{e}" do
      f = "valid_#{e}".intern
      g = e == :loot ? e : "#{e}s".intern
      r = Registry.new
      r << build(f)
      r << build(f)
      r << build(e == :ship ? :valid_station : :valid_ship)
      r.send(e == :loot ? e : "#{e}s".intern).size.should == 2
    end
  }

  context "adding entity" do
    it "resolves system references"

    it "enforces entity types" do
      g = build(:galaxy)
      r = Registry.new
      (r << g).should be_false
    end

    it "enforces unique ids" do
      s = build(:valid_ship)
      r = Registry.new
      (r << s).should be_true
      r.entities.size.should == 1

      (r << s).should be_false
      r.entities.size.should == 1
    end

    it "enforces entity validity" do
      s = build(:ship)
      s.id = nil
      r = Registry.new
      (r << s).should be_false
    end
  end

  it "runs command loop" do
    r = Registry.new
    r.instance_variable_get(:@event_loops).should include{ run_commands }
  end

end # describe Registry
end # module Manufactured

##  it "should permit transferring resources between entities" do
##    sys   = Cosmos::SolarSystem.new
##    ship  = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :solar_system => sys
##    station  = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :solar_system => sys
##
##    Manufactured::Registry.instance.create(ship)
##    Manufactured::Registry.instance.create(station)
##
##    res = Cosmos::Resource.new :type => 'metal', :name => 'gold'
##    ship.add_resource res.id, 50
##
##    Manufactured::Registry.instance.transfer_resource(nil, station, res.id, 25)
##    ship.resources[res.id].should == 50
##    station.resources[res.id].should be_nil
##
##    Manufactured::Registry.instance.transfer_resource(ship, nil, res.id, 25)
##    ship.resources[res.id].should == 50
##    station.resources[res.id].should be_nil
##
##    Manufactured::Registry.instance.transfer_resource(ship, station, res.id, 250)
##    ship.resources[res.id].should == 50
##    station.resources[res.id].should be_nil
##
##    nres = Cosmos::Resource.new :type => 'gem', :name => 'diamond'
##    Manufactured::Registry.instance.transfer_resource(ship, station, nres.id, 1)
##    ship.resources[res.id].should == 50
##    station.resources[res.id].should be_nil
##
##    Manufactured::Registry.instance.transfer_resource(ship, station, res.id, 20)
##    ship.resources[res.id].should == 30
##    station.resources[res.id].should == 20
##
##    res2 = Cosmos::Resource.new :type => 'metal', :name => 'silver'
##    station.add_resource res2.id, 500
##
##    # would exceed cargo capacity:
##    Manufactured::Registry.instance.transfer_resource(station, ship, res2.id, 200)
##    ship.resources[res2.id].should be_nil
##    station.resources[res2.id].should == 500
##  end
