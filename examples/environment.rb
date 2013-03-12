#!/usr/bin/ruby
# smaller environment than universe for testing specific aspects of integration
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'omega'

include Omega::Client::DSL

include Motel
include Motel::MovementStrategies

RJR::Logger.log_level= ::Logger::INFO

node = RJR::AMQPNode.new(:node_id => 'seeder', :broker => 'localhost')
# TODO read credentials from config
login node, 'admin', 'nimda'

galaxy 'Zeus' do |g|
  system 'Athena', 'HR1925', :location => Location.new(:x => 240, :y => -360, :z => 110) do |sys|
    asteroid gen_uuid, :location => Location.new(:x => 1922, :y => -930, :z => 2001) do |ast|
      resource :resource => rand_resource, :quantity => 325
    end
    asteroid gen_uuid, :location => Location.new(:x => 1533, :y => 998, :z => 640) do |ast|
      resource :resource => rand_resource, :quantity => 500
    end
  end

  system 'Aphrodite', 'V866', :location => Location.new(:x => -420, :y => 119, :z => 90) do |sys|
    asteroid gen_uuid, :location => Location.new(:x => -2500, :y => -137, :z => -320) do |ast|
      resource :resource => rand_resource, :quantity => 750
    end
    asteroid gen_uuid, :location => Location.new(:x => 343, :y => -492, :z => -2332) do |ast|
      resource :resource => rand_resource, :quantity => 750
    end
  end

  system 'Philo', 'HU1792', :location => Location.new(:x => -142, :y => -338, :z => 409) do |sys|
    planet 'Xeno',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.02,
                                                :eccentricity => 0.36, :semi_latus_rectum => 1080,
                                                :direction => Motel.random_axis) do |pl|
    end
  
    asteroid gen_uuid, :location => Location.new(:x => 479, :y => 432, :z => -1005) do |ast|
      resource :resource => rand_resource, :quantity => 550
    end
    asteroid gen_uuid, :location => Location.new(:x => 259, :y => -513, :z => -290) do |ast|
      resource :resource => rand_resource, :quantity => 550
    end

  end
end

athena    = system('Athena')
aphrodite = system('Aphrodite')
philo     = system('Philo')

jump_gate athena, aphrodite, :location => Location.new(:x => -950, :y => -950, :z => -950)
jump_gate athena, philo, :location => Location.new(:x => 950, :y => 950, :z => 950)
jump_gate aphrodite, athena, :location => Location.new(:x => -950, :y => 950, :z => -950)
jump_gate aphrodite, philo, :location => Location.new(:x => 950, :y => -950, :z => 950)
jump_gate philo, aphrodite, :location => Location.new(:x => 950, :y => -950, :z => 950)

schedule_event 60,
               Missions::Events::PopulateResource.new(:id => 'populate-resources',
                                                      :from_resources => Omega::Resources.all_resources,
                                                      :from_entities  => athena.asteroids + aphrodite.asteroids + philo.asteroids)
