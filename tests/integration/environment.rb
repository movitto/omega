#!/usr/bin/ruby
# smaller environment than universe for testing specific aspects of integration
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'omega'

include Omega::DSL

include Motel
include Motel::MovementStrategies

RJR::Logger.log_level= ::Logger::INFO
login 'admin',  :password => 'nimda'

galaxy 'Zeus' do |g|
  system 'Athena', 'HR1925', :location => Location.new(:x => 240, :y => -360, :z => 110) do |sys|
    asteroid gen_uuid, :location => Location.new(:x => 31, :y => -22, :z => 15) do |ast|
      resource :resource => rand_resource, :quantity => 25
    end
    asteroid gen_uuid, :location => Location.new(:x => 15, :y => 51, :z => 42) do |ast|
      resource :resource => rand_resource, :quantity => 250
    end
  end

  system 'Aphrodite', 'V866', :location => Location.new(:x => -420, :y => 119, :z => 90) do |sys|
    asteroid gen_uuid, :location => Location.new(:x => -25, :y => -17, :z => -32) do |ast|
      resource :resource => rand_resource, :quantity => 25
    end
    asteroid gen_uuid, :location => Location.new(:x => 10, :y => -42, :z => -22) do |ast|
      resource :resource => rand_resource, :quantity => 25
    end
  end

  system 'Philo', 'HU1792', :location => Location.new(:x => -142, :y => -338, :z => 409) do |sys|
    planet 'Xeno',
           :movement_strategy => Elliptical.new(:relative_to => :foci, :speed => 0.1,
                                                :eccentricity => 0.16, :semi_latus_rectum => 140,
                                                :direction => Motel.random_axis) do |pl|
    end
  
    asteroid gen_uuid, :location => Location.new(:x => 47, :y => 48, :z => -5) do |ast|
      resource :resource => rand_resource, :quantity => 25
    end
    asteroid gen_uuid, :location => Location.new(:x => 59, :y => -13, :z => -2) do |ast|
      resource :resource => rand_resource, :quantity => 25
    end

  end
end

jump_gate system('Athena'), system('Aphrodite'), :location => Location.new(:x => -150, :y => -150, :z => -150)
jump_gate system('Athena'), system('Philo'), :location => Location.new(:x => -150, :y => -150, :z => -150)
