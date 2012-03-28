# Cosmos entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

class Registry
  include Singleton
  attr_accessor :galaxies

  def initialize
    init
  end

  def init
    @galaxies = []
  end

  def find_entity(args = {})
    type = args[:type]
    name = args[:name]
    location = args[:location]
    # parent = args[:parent]
    entities = []

    return self if type == :universe

    @galaxies.each { |g|
      if type == :galaxy
        if name.nil? && location.nil?
          entities << g
        elsif (!name.nil?     && (name     == g.name       )) ||
              (!location.nil? && (location == g.location.id))
          return g
        end
      else
        g.solar_systems.each { |sys|
          if type == :solarsystem
            if name.nil? && location.nil?
              entities << sys
            elsif (!name.nil?     && (name     == sys.name       )) ||
                  (!location.nil? && (location == sys.location.id))
              return sys
            end
          elsif type == :star
            if name.nil? && location.nil?
              entities << sys.star
            elsif (!name.nil?     && (name     == sys.star.name       )) ||
                  (!location.nil? && (location == sys.star.location.id))
              return sys.star
            end
          else
            sys.planets.each { |p|
              if type == :planet
                if name.nil? && location.nil?
                  entities << p
                elsif (!name.nil?     && (name     == p.name       )) ||
                      (!location.nil? && (location == p.location.id))
                  return p
                end
              else
                p.moons.each { |m|
                  if type == :moon
                    if name.nil? && location.nil?
                      entities << m
                    elsif (!name.nil?     && (name     == m.name       )) ||
                          (!location.nil? && (location == m.location.id))
                      return m
                    end
                  end
                }
              end
            }
          end
        }
      end
    }
    return (!name.nil? || !location.nil?) ? nil : entities
  end

  def children
    @galaxies
  end

  def add_child(galaxy)
    @galaxies << galaxy unless @galaxies.include?(galaxy) || !galaxy.is_a?(Cosmos::Galaxy)
  end

  def has_children?
    return @galaxies.size > 0
  end

  def each_child(&bl)
    @galaxies.each { |g|
      bl.call g
      g.each_child &bl
    }
  end

  # Save state of the registry to specified stream
  def save_state(io)
    # TODO block new operations on registry
    galaxies.each { |galaxy| io.write galaxy.to_json + "\n" }
  end

  # restore state of the registry from the specified stream
  def restore_state(io)
    io.each { |json|
      entity = JSON.parse(json)
      if entity.is_a?(Cosmos::Galaxy)
        add_child(entity)
      end
    }
  end

end

end
