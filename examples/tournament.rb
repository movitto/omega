#!/usr/bin/ruby
# A simple tournament simulation
#
# Two users are created and assigned to missions whose goals
# are two destroy all of the other user's ships within the
# specified time limit
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/dsl'
require 'missions/dsl'
require 'rjr/nodes/tcp'

################################## dsl we're using

include Omega::Client::DSL
include Missions::DSL::Client

def mission_timeout
  1200 # = 20 min
end

def entity_loc
  rand_loc :min => 1000, :max => 3000
end

def system_loc
  rand_loc :min => 750, :max => 2000
end

################################# establish connection / login
node = RJR::Nodes::TCP.new(:node_id => 'client',
                           :host    => 'localhost',
                           :port    => '9090')
dsl.rjr_node = node
login 'admin', 'nimda'

################################# cosmos data
ninigi  = galaxy 'Ninigi'

hoderi  = system 'Hoderi', 'ZY20',
                 :galaxy   => ninigi,
                 :location => system_loc

hosueri = system 'Hosueri', 'JG54',
                 :galaxy   => ninigi,
                 :location => system_loc

hoori   = system 'Hoori', 'AR99',
                 :galaxy   => ninigi,
                 :location => system_loc

@available = [hoderi, hosueri, hoori].shuffle

def next_system
  @available.shift
end

################################# users & manufactured data
npcu = user 'npc-user', 'password', :npc => true

users = ['user1', 'user2']
users.each { |uid|
  user_system = next_system
  opponent    = uid == users.first ? users.last : users.first

  luser = user uid, 'password' do
    role :regular_user
  end

  lstation = station("#{uid}-station",
                     :user_id      => uid,
                     :type         => :manufacturing,
                     :solar_system => user_system,
                     :location     => entity_loc)

  lship = ship("#{uid}-ship",
               :user_id            => uid,
               :type               => :corvette,
               :solar_system       => user_system,
               :location           => entity_loc)

################################# mission data
  mission "mission-#{uid}",
    :title                => "Destroy #{uid}'s ships",
    :creator_id           => npcu.id,
    :timeout              => mission_timeout,
    :description          => "Destroy #{uid}'s ships",
    :requirements         => [],
  
    :assignment_callbacks => [
       :schedule_expiration_events,
      [:subscribe_to, :entity_destroyed, Event.check_victory_conditions]
      # TODO also assign other mission-#{opponent} to uid?
    ],
  
    :victory_conditions   => [
      [:entities_destroyed, {:owned_by => uid,
                             :of_type  => 'Manufactured::Ship'}]
    ],
  
    :victory_callbacks    => [
      :cleanup_expiration_events,
      [:fail_mission, "mission-#{opponent}"]
    ],
  
    :failure_callbacks    => [
      :cleanup_expiration_events
    ]
}


sleep 0.1 # XXX need to wait for mission creation notification to go through

invoke 'missions::assign_mission', 'mission-user1', 'user2'
invoke 'missions::assign_mission', 'mission-user2', 'user1'
