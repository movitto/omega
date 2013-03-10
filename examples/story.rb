#!/usr/bin/ruby
# sample story missions using omega dsl
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'omega'

include Omega::Client::DSL

include Missions

STARTING_SYSTEM = ARGV.shift

RJR::Logger.log_level= ::Logger::INFO

node = RJR::AMQPNode.new(:node_id => 'seeder', :broker => 'localhost')
# TODO read credentials from config
login node, 'admin', 'nimda'

starting_system = system(STARTING_SYSTEM)

macbeth  = user 'Macbeth',      'htebcam',      :npc => true
#lmacbeth = user 'Lady Macbeth', 'htebcam ydal', :npc => true
duncan   = user 'Duncan',       'nacnud',       :npc => true

castle_macbeth = station('castle-macbeth', :user_id => 'Macbeth',
                         :solar_system => starting_system, 
                         :location     => Location.new(:x => 750, :y => 750, :z => 750))

macbeth_ship   = ship('macbeth-ship', :user_id => 'Macbeth',
                      :solar_system => starting_system, 
                      :location     => Location.new(:x => 760, :y => 760, :z => 760))
macbeth_ship.dock_at(castle_macbeth)


mission gen_uuid, :title => 'Kill Duncan',
        :user        => macbeth, :time_to_complete => 360,
        :description => 'Macbeth needs you to assassinate Duncan, are you up to the task!?',

        :requirements => [ proc{ |mission, assigning_to, node|
          # ensure users have a ship docked at a common station
          created_by = mission.creator
          centities  = node.invoke_request('manufactured::get_entities', 'of_type', 'Manufactured::Ship', 'owned_by', created_by.id)
          cstats     = centities.collect { |s| s.docked_at }.compact

          aentities  = node.invoke_request('manufactured::get_entities', 'of_type', 'Manufactured::Ship', 'owned_by', assigning_to.id)
          astats     = aentities.collect { |s| s.docked_at }.compact

          !(cstats & astats).empty?
        }],

        :assignment_callbacks => [ proc{ |mission, node|
          # create new ship for duncan at random location in system
          athena  = node.invoke_request('cosmos::get_entity', 'with_id', 'Athena')
          duncan_ship = Manufactured::Ship.new(:id => 'duncan_ship-' + Motel.gen_uuid,
                                               :type => :corvette, # TODO autodefend on attack
                                               :user_id       => 'Duncan',
                                               :system_name   => 'Athena',
                                               :location      => Motel::Location.random)
          mission.mission_data['duncan_ship'] = duncan_ship
          node.invoke_request('manufactured::create_entity', duncan_ship)

          # add event for mission expiration
          Missions::Registry.instance.add_event("mission-#{mission.id}-expired",
                                                Time.now + mission.timeout) { |e|
            mission.failed!
          }

          # handle dunan ship being destroyed event
          Missions::Registry.instance.handle_event("#{duncan_ship.id}-_destroyed") { |e|
            mission.victory!
            Missions::Registry.instance.add_event("mission-#{mission.id}-succeeded", Time.now)
            # can create more ships or whatever instead
          }

          # subscribe to server side events
          node.invoke_request('manufactured::subscribe_to', duncan_ship.id, 'destroyed')
        }],

        :victory_conditions => [ proc{ |mission, node|
          # check if duncan's ship is destroyed
          entity = node.invoke_request('manufactured::get_entity', mission.mission_data['duncan_ship'].id)
          entity.nil? # or also search graveyard and verify hp == 0
        }],

        :victory_callbacks => [ proc{ |mission, node|
          # add resources to player's cargo
          # TODO better way to get user ship than this
          entity = node.invoke_request('manufactured::get_entity', 'of_type', 'Manufactured::Ship', 'owned_by', mission.assigned_to_id).first
          node.invoke_request('manufactured::add_resource', entity.id, 'metal-steel', 100)

          # from this point same logic as failure callbacks below
          duncan_ship = mission.mission_data['duncan_ship']
          node.invoke_request('manufactured::remove_callbacks', duncan_ship.id)
          Missions::Registry.instance.remove_event_handler("#{duncan_ship.id}_destroyed")
          Missions::Registry.instance.remove_event("mission-#{mission.id}-expired")
          node.invoke_request('missions::create_mission', mission.clone(:id => Motel.gen_uuid))
        }],

        :failure_callbacks => [proc{ |mission, node|
          # grab handle to duncan ship
          duncan_ship = mission.mission_data['duncan_ship']

          # remove server side events
          node.invoke_request('manufactured::remove_callbacks', duncan_ship.id)

          # remove duncan ship destroyed event handler
          Missions::Registry.instance.remove_event_handler("#{duncan_ship.id}_destroyed")

          # remove mission expiration event
          Missions::Registry.instance.remove_event("mission-#{mission.id}-expired")

          # TODO flush other mission related events?

          # create a new mission based on this one
          node.invoke_request('missions::create_mission', mission.clone(:id => Motel.gen_uuid))
        }]
