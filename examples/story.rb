#!/usr/bin/ruby
# sample story missions using omega dsl
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'omega'

include Omega::Client::DSL

include Missions

##################################################### init

STARTING_SYSTEM = ARGV.shift

RJR::Logger.log_level= ::Logger::INFO

node = RJR::AMQPNode.new(:node_id => 'seeder', :broker => 'localhost')
# TODO read credentials from config
login node, 'admin', 'nimda'

starting_system = system(STARTING_SYSTEM)

##################################################### users

macbeth  = user 'Macbeth',      'htebcam',      :npc => true
duncan   = user 'Duncan',       'nacnud',       :npc => true

hamlet   = user 'Hamlet',       'telmah',       :npc => true
claudius = user 'Claudius',     'suidualc',     :npc => true

othello  = user 'Othello',      'ollehto',      :npc => true
iago     = user 'Iago',         'ogai',         :npc => true

##################################################### entities

# TODO logout as admin, login as macbeth/hamlet/othello so as to properly set creator_user_id

castle_macbeth = station('castle-macbeth', :user_id => 'Macbeth',
                         :solar_system => starting_system, 
                         :location     => Motel::Location.new(:x => -950, :y => 450, :z => -750))

macbeth_ship   = ship('macbeth-ship', :user_id => 'Macbeth',
                      :solar_system => starting_system,
                      :location     => Motel::Location.new(:x => -960, :y => 460, :z => -760))
macbeth_ship.dock_to(castle_macbeth) if macbeth_ship.docked_at.nil?

hamlet_ship    = ship('hamlet-ship', :user_id => 'Hamlet',
                      :solar_system => starting_system,
                      :location     => Motel::Location.new(:x => 342, :y => -1132, -286))

othello_ship   = ship('othello-ship', :user_id => 'Othello',
                      :solar_system => starting_system,
                      :location     => Motel::Location.new(:x => 501, :y => 466, :z => -2495)


##################################################### attack missions

mission gen_uuid, :title => 'Kill Duncan',
        :creator_user_id => macbeth.id, :timeout => 360,
        :description => 'Macbeth needs you to assassinate Duncan, are you up to the task!?',

        :requirements => proc{ |mission, assigning_to, node|
          # ensure users have a ship docked at a common station
          created_by = mission.creator
          centities  = node.invoke_request('manufactured::get_entities', 'of_type', 'Manufactured::Ship', 'owned_by', created_by.id)
          cstats     = centities.collect { |s| s.docked_at.nil? ? nil : s.docked_at.id }.compact

          aentities  = node.invoke_request('manufactured::get_entities', 'of_type', 'Manufactured::Ship', 'owned_by', assigning_to.id)
          astats     = aentities.collect { |s| s.docked_at.nil? ? nil : s.docked_at.id }.compact

          !(cstats & astats).empty?
        },

        :assignment_callbacks =>  proc{ |mission, node|
          # create new ship for duncan at random location in system
          athena  = node.invoke_request('cosmos::get_entity', 'with_id', 'Athena')
          duncan_ship = Manufactured::Ship.new :id => 'duncan_ship-' + Motel.gen_uuid,
                                               :type => :corvette, # TODO autodefend on attack
                                               :user_id       => 'Duncan',
                                               :system_name   => 'Athena',
                                               :location      => Motel::Location.new({:x => -930, :y => 470, :z => -720}) #Motel::Location.random
          mission.mission_data['duncan_ship'] = duncan_ship
          # TODO only if ship does not exist
          node.invoke_request('manufactured::create_entity', duncan_ship)

          # add event for mission expiration
          expired = Missions::Event.new :id      => "mission-#{mission.id}-expired",
                                        :timestamp => mission.assigned_time + mission.timeout, :callbacks => [proc{ |e|
                                           # TODO ensure not victorious, move this to new event class, lock registry
                                           mission.failed! # if mission.expired?
                                         }]

          Missions::Registry.instance.unsafely_run { # XXX need to unlock registry
            Missions::Registry.instance.create expired

            # handle dunan ship being destroyed event
            Missions::Registry.instance.handle_event("#{duncan_ship.id}_destroyed") { |e|
              # TODO ensure not failed, check victory conditions, lock registry
              mission.victory! # if mission.completed?
              victory = Missions::Event.new :id => "mission-#{mission.id}-succeeded", :timestamp => Time.now
              Missions::Registry.instance.create victory
              # can create more ships or whatever instead
            }
          }

          # subscribe to server side events
          node.invoke_request('manufactured::subscribe_to', duncan_ship.id, 'destroyed')
        },

        :victory_conditions => proc{ |mission, node|
          # check if duncan's ship is destroyed
          entity = node.invoke_request('manufactured::get_entity', mission.mission_data['duncan_ship'].id)
          entity.nil? # or also search graveyard and verify hp == 0
        },

        :victory_callbacks => proc{ |mission, node|
          # add resources to player's cargo
          # TODO better way to get user ship than this
          entity = node.invoke_request('manufactured::get_entity', 'of_type', 'Manufactured::Ship', 'owned_by', mission.assigned_to_id).first
          node.invoke_request('manufactured::add_resource', entity.id, 'metal-steel', 50)

          # from this point same logic as failure callbacks below
          duncan_ship = mission.mission_data['duncan_ship']
          node.invoke_request('manufactured::remove_callbacks', duncan_ship.id)
          Missions::Registry.instance.remove_event_handler("#{duncan_ship.id}_destroyed")
          Missions::Registry.instance.remove("mission-#{mission.id}-expired")
          new_mission = mission.clone :id => Motel.gen_uuid
          new_mission.clear_assignment!
          node.invoke_request('missions::create_mission', new_mission)
        },

        :failure_callbacks => proc{ |mission, node|
          # grab handle to duncan ship
          duncan_ship = mission.mission_data['duncan_ship']

          # remove server side events
          node.invoke_request('manufactured::remove_callbacks', duncan_ship.id)

          # remove duncan ship destroyed event handler
          Missions::Registry.instance.remove_event_handler("#{duncan_ship.id}_destroyed")

          # remove mission expiration event
          Missions::Registry.instance.remove("mission-#{mission.id}-expired")

          # TODO flush other mission related events?

          # create a new mission based on this one
          new_mission = mission.clone :id => Motel.gen_uuid
          new_mission.clear_assignment!
          node.invoke_request('missions::create_mission', new_mission)
        }

mission gen_uuid, :title => 'Take Claudius Down',
        :creator_user_id => hamlet.id, :timeout => 360,
        :description => '',

        :assignment_callbacks =>  proc{ |mission, node|
        },

        :victory_conditions => proc{ |mission, node|
        },

        :victory_callbacks => proc{ |mission, node|
        },

        :failure_callbacks => proc{ |mission, node|
        }

mission gen_uuid, :title => 'Put an End to Iago'
        :creator_user_id => othello.id, :timeout => 360,
        :description => '',

        :assignment_callbacks =>  proc{ |mission, node|
        },

        :victory_conditions => proc{ |mission, node|
        },

        :victory_callbacks => proc{ |mission, node|
        },

        :failure_callbacks => proc{ |mission, node|
        }

mission gen_uuid, :title => 'TODO',
        :creator_user_id => , :timeout => 360,
        :description => '',

        :assignment_callbacks =>  proc{ |mission, node|
        },

        :victory_conditions => proc{ |mission, node|
        },

        :victory_callbacks => proc{ |mission, node|
        },

        :failure_callbacks => proc{ |mission, node|
        }


mission gen_uuid, :title => 'TODO',
        :creator_user_id => , :timeout => 360,
        :description => '',

        :assignment_callbacks =>  proc{ |mission, node|
        },

        :victory_conditions => proc{ |mission, node|
        },

        :victory_callbacks => proc{ |mission, node|
        },

        :failure_callbacks => proc{ |mission, node|
        }

##################################################### mining/transport/loot missions

[['metal-steel', 500, 500, 100], ['metal-plantinum', 100, 100, 250],
 ['gem-diamond', 100, 200, 200], ['fuel-uranium',   1000, 200, 100],
 ['adhesive-cellulose', 5000, 1000, 50]].each { |res,q1,q2,q3|

# mining
mission gen_uuid, :title => "Collect #{q1} of #{res}",
        :creator_user_id => , :timeout => 3600,
        :description => '',

        :assignment_callbacks =>  proc{ |mission, node|
        },

        :victory_conditions => proc{ |mission, node|
        },

        :victory_callbacks => proc{ |mission, node|
        },

        :failure_callbacks => proc{ |mission, node|
        }

# transport
mission gen_uuid, :title => "Move #{q2} of #{res} from ...",
        :creator_user_id => , :timeout => 3600,
        :description => '',

        :assignment_callbacks =>  proc{ |mission, node|
        },

        :victory_conditions => proc{ |mission, node|
        },

        :victory_callbacks => proc{ |mission, node|
        },

        :failure_callbacks => proc{ |mission, node|
        }

# loot
mission gen_uuid, :title => "Scavange #{q3} of #{res}",
        :creator_user_id => , :timeout => 3600,
        :description => '',

        :assignment_callbacks =>  proc{ |mission, node|
        },

        :victory_conditions => proc{ |mission, node|
        },

        :victory_callbacks => proc{ |mission, node|
        },

        :failure_callbacks => proc{ |mission, node|
        }
}

##################################################### research missions (TODO)
