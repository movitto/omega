# Cosmos entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

class Registry
  include Singleton
  attr_accessor :galaxies

  def initialize
    @galaxies = []
  end

  def find_entity(args = {})
    type = args[:type]
    name = args[:name]
    # parent = args[:parent]
    entities = []

    return self if type == :universe

    @galaxies.each { |g|
      if type == :galaxy
        if name.nil?
          entities << g
        elsif name == g.name
          return g
        end
      else
        g.solar_systems.each { |sys|
          if type == :solarsystem
            if name.nil?
              entities << sys
            elsif name == sys.name
              return sys
            end
          elsif type == :star
            if name.nil?
              entities << sys.star
            elsif name == sys.star.name
              return sys.star
            end
          else
            sys.planets.each { |p|
              if type == :planet
                if name.nil?
                  entities << p
                elsif name == p.name
                  return p
                end
              else
                p.moons.each { |m|
                  if type == :moon
                    if name.nil?
                      entities << m
                    elsif name == m.name
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
    return name.nil? ? entities : nil
  end

  def add_child(galaxy)
    # TODO raise exception unless galaxy.is_a? Galaxy
    @galaxies << galaxy
  end
end

end
