# Manufactured entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'singleton'

module Manufactured

class Registry
  include Singleton

  # entities we are tracking
  attr_reader :ships
  attr_reader :stations
  attr_reader :fleets

  # attack commands client has issues to be regularily run
  attr_reader :attack_commands

  ATTACK_POLL_DELAY = 0.5 # TODO make configurable?

  def initialize
    @ships    = []
    @stations = []
    @fleets   = []
    @attack_commands = []

    @terminate_attack_cycle = false
    @attack_thread = Thread.new { attack_cycle }
  end

  def find(args = {})
    id        = args[:id]
    parent_id = args[:parent_id]
    user_id   = args[:user_id]
    type      = args[:type]
    location_id = args[:location_id]

    entities = []

    [@ships, @stations, @fleets].each { |entity_array|
      entity_array.each { |entity|
        entities << entity if (id.nil?        || entity.id         == id)        &&
                              (parent_id.nil? || entity.parent.id  == parent_id) &&  # FIXME fleet parent could be nil (autodelete fleet if no ships?)
                              (user_id.nil?   || entity.user_id    == user_id)   &&
                              (location_id.nil? || (entity.location && entity.location.id == location_id)) &&
                              (type.nil?      || entity.class.to_s == type)

      }
    }
    entities
  end

  def create(entity)
    if entity.is_a?(Manufactured::Ship)
      @ships << entity
    elsif entity.is_a?(Manufactured::Station)
      @stations << entity
    elsif entity.is_a?(Manufactured::Fleet)
      @fleets << entity
    end
  end

  # add new attack command to run
  def schedule_attack(args = {})
    @attack_commands << AttackCommand.new(args)
  end

  # invoked in thread to periodically invoke attack commands
  def attack_cycle
    until @terminate_attack_cycle
      # run attack if appropriate
      @attack_commands.each { |ac|
        ac.attack! if ac.attackable?
      }

      # remove attack commands no longer necessary
      @attack_commands.reject! { |ac| ac.remove? }

      # remove ships w/ <= 0 hp
      @ships.reject! { |sh| sh.hp <= 0 }

      sleep ATTACK_POLL_DELAY
    end
  end

  # Save state of the registry to specified stream
  def save_state(io)
    # TODO block new operations on registry
    ships.each { |ship| io.write ship.to_json + "\n" }
    stations.each { |station| io.write station.to_json + "\n" }
  end

  # restore state of the registry from the specified stream
  def restore_state(io)
    io.each { |json|
      entity = JSON.parse(json)
      if entity.is_a?(Manufactured::Ship) || entity.is_a?(Manufactured::Station)
        create(entity)
      end
    }
  end


end

end
