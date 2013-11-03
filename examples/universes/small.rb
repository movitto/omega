#!/usr/bin/ruby
# A smaller universe
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'

require 'omega'
require 'omega/client/dsl'
require 'rjr/nodes/amqp'

include Omega::Client::DSL

include Motel
include Motel::MovementStrategies

RJR::Logger.log_level= ::Logger::INFO

dsl.rjr_node =
  RJR::Nodes::AMQP.new(:node_id => 'seeder', :broker => 'localhost')

# TODO read credentials from config
login 'admin', 'nimda'

galaxy 'Zeus' do |g|
  system 'Athena', 'HR1925', :location => loc(620,-720,230) do |sys|
    asteroid gen_uuid, :location => loc(-2000,-1040,-1000) do |ast|
      resource :resource => rand_resource, :quantity => 325
    end

    asteroid gen_uuid, :location => loc(2097,283,-1020) do |ast|
      resource :resource => rand_resource, :quantity => 500
    end

    asteroid gen_uuid, :location => loc(1537,1296,-3015) do |ast|
      resource :resource => rand_resource, :quantity => 550
    end

    asteroid gen_uuid, :location => loc(2664,-1539,-1770) do |ast|
      resource :resource => rand_resource, :quantity => 550
    end

    asteroid gen_uuid, :location => loc(-1200, -1239,800) do |ast|
      resource :resource => rand_resource, :quantity => 750
    end

    asteroid gen_uuid, :location => loc(1280,-760,-1960) do |ast|
      resource :resource => rand_resource, :quantity => 750
    end
  end

  system 'Aphrodite', 'V866', :location => loc(-1160,357,270) do |sys|
    asteroid_field :locations => [rand_location(:min => 500, :max => 2000),
                                  rand_location(:min => 500, :max => 2000)]
  end

  system 'Philo', 'HU1792', :location => loc(-754,627,481) do |sys|
    planet 'Xeno', :movement_strategy =>
      orbit(:speed => 0.02, :e => 0.36, :p => 1080,
            :direction => random_axis(:orthogonal_to => [0,1,0]))
  
    planet 'Aesop', :movement_strategy =>
      orbit(:e => 0.65, :speed => 0.008, :p => 6000,
            :direction => random_axis(:orthogonal_to => [0,1,0]))

    asteroid_belt :e => 0.62, :p => 3000,
                  :direction => random_axis(:orthogonal_to => [0,1,0])
  end
end

athena    = system('Athena')
aphrodite = system('Aphrodite')
philo     = system('Philo')

jump_gate athena,    aphrodite, :location => loc(-1050,-1050,-1050)
jump_gate athena,    philo,     :location => loc( 1050, 1050, 1050)
jump_gate aphrodite, athena,    :location => loc(-1050, 1050,-1050)
jump_gate aphrodite, philo,     :location => loc( 1050,-1050, 1050)
jump_gate philo,     aphrodite, :location => loc( 1050,-1050, 1050)

schedule_event 6000,
  Missions::Events::PopulateResource.new(
    :id =>
      'populate-resources',
    :from_resources =>
      Omega::Resources.all_resources,
    :from_entities  =>
      athena.asteroids    +
      aphrodite.asteroids +
      philo.asteroids)
