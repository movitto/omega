#!/usr/bin/ruby
# A smaller universe
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/boilerplate'

login 'admin', 'nimda'

galaxy 'Zeus' do |g|
  system 'Athena', 'HR1925' do |sys|
    asteroid gen_uuid do |ast|
      resource :resource => rand_resource, :quantity => 325
    end

    asteroid gen_uuid do |ast|
      resource :resource => rand_resource, :quantity => 500
    end

    asteroid gen_uuid do |ast|
      resource :resource => rand_resource, :quantity => 550
    end

    asteroid gen_uuid do |ast|
      resource :resource => rand_resource, :quantity => 550
    end

    asteroid gen_uuid do |ast|
      resource :resource => rand_resource, :quantity => 750
    end

    asteroid gen_uuid do |ast|
      resource :resource => rand_resource, :quantity => 750
    end
  end

  system 'Aphrodite', 'V866' do |sys|
    asteroid_field :num => 2
  end

  system 'Philo', 'HU1792' do |sys|
    planet 'Xeno'
    planet 'Aesop'
    asteroid_belt
  end
end

athena    = system('Athena')
aphrodite = system('Aphrodite')
philo     = system('Philo')

jump_gate athena,    aphrodite
jump_gate athena,    philo
jump_gate aphrodite, athena
jump_gate aphrodite, philo
jump_gate philo,     aphrodite

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
