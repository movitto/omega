#!/usr/bin/ruby
#
# Uses the Omega DSL to seed the omega-server w/ simulation data including
# a universe and multiple users w/ ships / stations
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'

require 'omega/client/dsl'
require 'omega/client/entities/cosmos'
require 'rjr/nodes/amqp'
require 'motel/location'
require 'motel/movement_strategies/elliptical'
require 'motel/movement_strategies/follow'

include Omega::Client::DSL

include Motel
include Motel::MovementStrategies

RJR::Logger.log_level= ::Logger::INFO

#dsl.parallel = true
node = RJR::Nodes::AMQP.new(:node_id => 'seeder', :broker => 'localhost', :host => 'localhost', :port => 8080)
dsl.rjr_node = node
Omega::Client::Trackable.node.rjr_node = node # XXX
login 'admin', 'nimda'

# create a sample universe 
0.upto(2) { |i|
  gid = "galaxy#{i}"
  galaxy gid do |g|
    0.upto(rand(2)) { |j|
      sid = "system#{i}-#{j}"
      stid = "star#{i}-#{j}"
      system sid, stid, :location => rand_location do |s|
        0.upto(rand(2)) { |k|
          pid = "planet#{i}-#{j}-#{k}"
          planet pid,
                 :movement_strategy =>
                   Elliptical.random(:relative_to => Elliptical::FOCI,
                                     :max_e => 0.78, :min_e => 0.24,
                                     :max_l => 1500, :min_l => 1000,
                                     :max_s => 0.01, :min_s => 0.001) do |p|
            0.upto(rand(2)) { |l|
              mid = "moon#{i}-#{j}-#{k}-#{l}"
              moon mid, :location => rand_location
            }
          end
        }
      end
    }
  end
}

# connect systems
systems = Omega::Client::SolarSystem.get_all
systems_to_connect = systems
0.upto(systems_to_connect.size-2){ |i|
  s1 = s2 = 0
  until s1 != s2
    s1,s2 = rand(systems_to_connect.size), rand(systems_to_connect.size)
  end
  sys1,sys2 = systems_to_connect[s1],systems_to_connect[s2]
  jump_gate sys1, sys2, :location => rand_location
  jump_gate sys2, sys1, :location => rand_location
  systems_to_connect.delete_at(s1)
}

# create a series of random locations
0.upto(500) { |i|
  # TODO rand movement strategy
  dsl.notify 'motel::create_location',
               rand_location(:id => i,
                             :restrict_view   => false,
                             :restrict_modify => false)
}

# create users and manufactured entities
0.upto(5) { |i|
  uid = "user#{i}"
  user uid, "#{i}resu" do |u|
    role :regular_user
  end

  user "#{uid}-enemy", "#{i}resu" do |u|
    role :regular_user
  end

  0.upto(3) { |j|
    #dsl_thread { # would like to uncomment, but need a way to reference variables outside scope of thread
      eid = "entity_#{i}-#{j}"
      # select random system / location
      rnd = Random.new
      sys = systems[rnd.rand(systems.size)]
      shl = rand_location

      case j % 3
      when 0 then
        # create mining ship w/ existing resources
        sh  = ship(eid) do |ship|
                ship.cargo_capacity = 10000000
                ship.type     = :mining
                ship.user_id  = uid
                ship.solar_system = sys
                ship.location = shl
                ship.add_resource Cosmos::Resource.new(:id => "metal-#{eid}_resource", :quantity => 5000)
              end
        shl = sh.location

        # create resource source nearby
        asteroid "#{eid}_target", :location     => shl + [10,10,10],
                                  :solar_system => sys do |ast|
          resource :name => "#{eid}_target_resource",
                   :type => :metal, :quantity => 5000000
        end

        # create a transport ship nearby
        sh  = ship("#{eid}-transport") do |ship|
                ship.cargo_capacity = 10000000
                ship.type     = :transport
                ship.user_id  = uid
                ship.solar_system = sys
                ship.location = shl + [-10, -10, -10]
              end

      when 1 then
        sh  = ship(eid) do |ship|
                ship.type     = :corvette
                ship.user_id  = uid
                ship.solar_system = systems.sample # selects random element, ruby ftw! :-)
                ship.location = rand_location
              end
        shl = sh.location

        # create a opponent ship nearby, set to follow corvette
        oshl = shl + [-10, -10, -10]
        oshl.movement_strategy = Follow.new :tracked_location_id => shl.id,
                                            :distance => 10, :speed => 5
        osh = ship("#{eid}-opponent") do |ship|
                ship.hp = 100000
                ship.type     = :battlecruiser
                ship.user_id  = "#{uid}-enemy"
                ship.solar_system = sys
                ship.location = oshl
              end

      else
        sh  = station(eid) do |st|
                st.type    = :manufacturing
                st.user_id = uid
                st.solar_system = systems.sample
                st.location = rand_location
                st.cargo_capacity = 10000000
                st.add_resource Cosmos::Resource.new(:id => "metal-#{eid}_resource",
                                                     :quantity => 50000)
              end

      end
    #}
  }
}

dsl.join
