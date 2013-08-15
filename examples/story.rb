#!/usr/bin/ruby
# Sample story missions using omega dsl
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'

require 'omega'
require 'omega/client/dsl'
require 'missions/dsl'
require 'rjr/nodes/amqp'

include Omega::Client::DSL
include Missions::DSL::Client

##################################################### init

RJR::Logger.log_level= ::Logger::INFO

# TODO read credentials from config
dsl.rjr_node = RJR::Nodes::AMQP.new(:node_id => 'seeder', :broker => 'localhost')
login 'admin', 'nimda'

STARTING_SYSTEMS = ARGV.collect { |s| system(s) }
def rand_system ; STARTING_SYSTEMS.sample ; end

##################################################### users

ceasar   = user 'Ceasar',       'rasaec',       :npc => true

shennong = user 'Shennong',     'gnonnehs',     :npc => true
chiyou   = user 'ChiYou',       'ouyihc',       :npc => true

macbeth  = user 'Macbeth',      'htebcam',      :npc => true
duncan   = user 'Duncan',       'nacnud',       :npc => true

hamlet   = user 'Hamlet',       'telmah',       :npc => true
claudius = user 'Claudius',     'suidualc',     :npc => true

othello  = user 'Othello',      'ollehto',      :npc => true
iago     = user 'Iago',         'ogai',         :npc => true

octavius = user 'Octavius',     'suivatco',     :npc => true
marcus   = user 'Marcus',       'sucram',       :npc => true

titus    = user 'Titus',        'sutit',        :npc => true
tamora   = user 'tamora',       'aromat',       :npc => true

##################################################### entities

# TODO logout as admin, login as macbeth/hamlet/othello so as to properly set creator_user_id

castle_macbeth =
  station('castle-macbeth', :user_id => 'Macbeth', :type => :defense,
          :solar_system => rand_system,
          :location     => Motel::Location.new(:x => -950, :y => 450, :z => -750))

macbeth_ship =
  ship('macbeth-ship', :user_id => 'Macbeth', :type => :destroyer,
       :system_id => castle_macbeth.system_id,
       :location     => Motel::Location.new(:x => -960, :y => 460, :z => -760))
#macbeth_ship.dock_to(castle_macbeth) if macbeth_ship.docked_at.nil?

elsinore =
  station('elsinore', :user_id => 'Hamlet', :type => :mining,
          :solar_system => rand_system, 
          :location     => Motel::Location.new(:x => 928, :y => -67, :z => 102))

hamlet_ship =
  ship('hamlet-ship', :user_id => 'Hamlet', :type => :corvette,
       :system_id => elsinore.system_id,
       :location     => Motel::Location.new(:x => 920, :y => -59, :z => 100))
#hamlet_ship.dock_to(elsinore) if hamlet_ship.docked_at.nil?

cyprus =
  station('cyprus', :user_id => 'Othello', :type => :commerce,
          :solar_system => rand_system, 
          :location     => Motel::Location.new(:x => -1950, :y => 1718, :z => 418))

othello_ship =
  ship('othello-ship', :user_id => 'Othello', :type => :battlecruiser,
       :system_id => cyprus.system_id,
       :location     => Motel::Location.new(:x => -1975, :y => 1710, :z => 420))
#othello_ship.dock_to(cyprus) if othello_ship.docked_at.nil?

rome =
  station('rome', :user_id => 'Ceasar', :type => :commerce,
          :solar_system => rand_system, 
          :location     => Motel::Location.new(:x => 250, :y => 250, :z => 250))

octavius_ship =
  ship('octavius-ship', :user_id => 'Octavius', :type => :exploration,
       :system_id => rome.system_id,
       :location     => Motel::Location.new(:x => 270, :y => 290, :z => 270))
#octavius_ship.dock_to(rome) if octavius_ship.docked_at.nil?

titus_ship =
  ship('titus-ship', :user_id => 'Titus', :type => :bomber,
       :system_id => rome.system_id,
       :location     => Motel::Location.new(:x => 230, :y => 270, :z => 230))
#titus_ship.dock_to(rome) if titus_ship.docked_at.nil?

penglai =
  station('penglai', :user_id => 'Shennong', :type => :science,
          :solar_system => rand_system, 
          :location     => Motel::Location.new(:x => 2950, :y => 2950, :z => 2950))

youdu =
  station('youdu', :user_id => 'Shennong', :type => :technology,
          :solar_system => rand_system, 
          :location     => Motel::Location.new(:x => -1950, :y => -1950, :z => -1950))

##################################################### attack missions

[{:title       => 'Kill Duncan',
  :description => 'Macbeth needs you to assassinate Duncan, are you up to the task!?',
  :creator     =>  macbeth,
  :opponent    =>  duncan,
  :location    =>  Motel::Location.random(:max => 2000),
  :reward      => 'metal-steel' },

 {:title       => 'Take Claudius Down',
  :description => 'The time for vengance is at hand, help Hamlet seek retribution for his father',
  :creator     =>  hamlet,
  :opponent    =>  claudius,
  :location    =>  Motel::Location.random(:max => 2000),
  :reward      => 'metal-steel' },

 {:title       => 'Put an End to Iago',
  :description => 'Alas Iago succeeded with his evil schemes, but he needs to be punished for his acts.',
  :creator     =>  othello,
  :opponent    =>  iago,
  :location    =>  Motel::Location.random(:max => 2000),
  :reward      => 'metal-steel' },

 {:title       => 'Eliminate Marcus Antonius',
  :description => 'Help Octavius defeat Mark Antony to consolidate power and form the empire',
  :creator     => octavius,
  :opponent    => marcus,
  :location    =>  Motel::Location.random(:max => 2000),
  :reward      => 'metal-steel' },

 {:title       => 'Finish off Tamora',
  :description => 'The bloodshed has gone on for too long, put an end to the Queen of the Goths',
  :creator     => titus,
  :opponent    => tamora,
  :location    =>  Motel::Location.random(:max => 2000),
  :reward      => 'metal-steel' }

].each { |msn|

es = msn[:opponent].id.downcase + '_ship'

mission gen_uuid, :title => msn[:title],
  :creator_user_id => msn[:creator].id, :timeout => 360,
  :description => msn[:description],

  :requirements => Requirements.shared_station,

  :assignment_callbacks =>
    [Assignment.create_entity(es,
      :id       => "#{es}-" + Motel.gen_uuid,
      :type     => :corvette, # TODO autodefend on attack
      :user_id  => msn[:opponent].id,
      :solar_system => rand_system,
      :location    => msn[:location]),
     Assignment.schedule_expiration_event,
     Assignment.subscribe_to(es, "destroyed",
                             Event.create_victory_event)],

  :victory_conditions =>
    Query.check_entity_hp(es),

  :victory_callbacks => 
    [Resolution.add_resource(Cosmos::Resource.new(:material_id => msn[:reward],
                                                  :quantity => 50)),
     Resolution.update_user_attributes,
     Resolution.cleanup_events(es, 'destroyed'),
     Resolution.recycle_mission],

  :failure_callbacks =>
    [Resolution.update_user_attributes,
     Resolution.cleanup_events(es, 'destroyed'),
     Resolution.recycle_mission]
}

##################################################### mining/transport/loot missions

     [['metal',    'steel',     500,  500, 100, youdu, penglai],
      ['metal',    'plantinum', 100,  100, 250, youdu, penglai],
      ['gem',      'diamond',   100,  200, 200, youdu, penglai],
      ['fuel',     'uranium',   1000, 200, 100, youdu, penglai],
      ['adhesive', 'cellulose', 5000, 1000, 50, youdu, penglai]].
each { |type,       name,       q1,   q2,  q3,  src,   dst|

mid = gen_uuid

# mining
mission mid, :title => "Collect #{q1} of #{type}-#{name}",
  :creator_user_id => shennong.id, :timeout => 3600,
  :description => 'The emperor needs you to collect resources for the good of the people',
  :mission_data => { :target => "#{type}-#{name}", :quantity => q1, :resources => Hash.new(0) },

  :assignment_callbacks =>
    [Assignment.store(mid + '-mining-ships',
        Query.user_ships(:type => :mining )), # FIXME misses any mining ships created after assignment
     Assignment.create_asteroid(mid + '-asteroid',
      :name => mid,
      :solar_system => rand_system,
      :location => Motel::Location.random(:max => 2000)),
     Assignment.create_resource(mid + '-asteroid',
                                :material_id => "#{type}-#{name}",
                                :quantity    => q1),
     Assignment.schedule_expiration_event,
     Assignment.subscribe_to(mid + '-mining-ships', "resource_collected",
                                         Event.resource_collected)],

  :victory_conditions =>
    Query.check_mining_quantity,

  # TODO also support a consolidated victory/failure callbacks mechanism ('completed_callbacks)

  :victory_callbacks => 
    [Resolution.update_user_attributes,
     Resolution.cleanup_events(mid + '-mining-ships', 'resource_collected'),
     Resolution.recycle_mission],

  :failure_callbacks =>
    [Resolution.update_user_attributes,
     Resolution.cleanup_events(mid + '-mining-ships', 'resource_collected'),
     Resolution.recycle_mission]

# transport
mission gen_uuid, :title => "Move #{q2} of #{type}-#{name} from #{src.id} #{dst.id}",
  :creator_user_id => shennong.id, :timeout => 3600,
  :description => "The will of the people dictates resources be moved from #{src} to #{dst}",
  :mission_data => { :check_transfer => { :dst => dst, :q => q2, :rs => "#{type}-#{name}" } },

  :requirements => Requirements.docked_at(src),
                   # TODO also that ship has capacity for resources

  :assignment_callbacks => 
    [Assignment.store(mid + '-ship',
       Query.user_ship(:docked_at_id => src.id )),
     Assignment.add_resource(mid + '-ship',
                             :material_id => "#{type}-#{name}",
                             :quantity    => q2),
     Assignment.schedule_expiration_event,
     Assignment.subscribe_to(mid + '-ship', 'transferred_to',
                             Event.transferred_out)],

  :victory_conditions => Query.check_transfer,

  :victory_callbacks =>
    [Resolution.update_user_attributes,
     Resolution.cleanup_events(mid + '-ship', 'transfer'),
     Resolution.recycle_mission],

  :failure_callbacks =>
    [Resolution.update_user_attributes,
     Resolution.cleanup_events(mid + '-ship', 'transfer'),
     Resolution.recycle_mission]

# loot
eid = "#{mid}-enemy-#{rand(2)}"
mission gen_uuid, :title => "Scavange #{q3} of #{type}-#{name}",
  :creator_user_id => shennong.id, :timeout => 3600,
  :description => 'Shennong commands you retrieve resource from the tyrant Chi You, will you heed his call?',
  :mission_data => { :loot => [], :check_loot => {:res => "#{type}-#{name}", :q => q3} },

  :assignment_callbacks =>
    [Assignment.store(mid + '-ships',
                      Query.user_ships)] + # FIXME misses any ships created after assignment
    Array.new(3) { |i|
      Assignment.create_entity("#{mid}-enemy-#{i}",
        :id       => Motel.gen_uuid,
        :type     => :corvette, # TODO autodefend on attack
        :user_id  => chiyou.id,
        :solar_system => rand_system,
        :location    => rand_location)
    } +
    [Assignment.add_resource(eid,
                             :material_id => "#{type}-#{name}",
                             :quantity    => q3),
     Assignment.schedule_expiration_event,
     Assignment.subscribe_to(mid + '-ships', 'collected_loot',
                             Event.collected_loot)],

  :victory_conditions => Event.collected_loot,

  :victory_callbacks =>
    [Resolution.update_user_attributes,
     Resolution.cleanup_events(mid + '-ships', 'collected_loot'),
     Resolution.recycle_mission],

  :failure_callbacks =>
    [Resolution.update_user_attributes,
     Resolution.cleanup_events(mid + '-ships', 'collected_loot'),
     Resolution.recycle_mission]
}

##################################################### research missions (TODO)
