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
        [['attacked', @attacker, @defender],
         ['attacked_stopped', @attacker, @defender],
         ['defended', @attacker, @defender],
         ['defended_stopped', @attacker, @defender],
         ['destroyed', @attacker, @defender],
         ['resource_depleted', @miner, @rs],
         ['mining_stopped', 'resource_depleted', @miner, @rs],
         ['resource_collected', @miner, @rs],
         ['construction_complete', @station, @constru],
         ['partial_construction', @station, @constru, 0.5]]
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
  end

end # describe Manufactured
end # module Events
end # module Missions
