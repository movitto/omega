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

  def find_entity(type, name)
    return self if type == :universe

    @galaxies.each { |g|
      return g if type == :galaxy && name == g.name
      g.solar_systems.each { |sys|
        return sys if type == :solarsystem && name == sys.name
        return sys.star if type == :star && name == sys.star.name
        sys.planets.each { |p|
          return p if type == :planet && name == p.name
          p.moons.each { |m|
            return m if type == :moon && name == m.name
          }
        }
      }
    }
    return nil
  end

  def add_child(galaxy)
    # TODO raise exception unless galaxy.is_a? Galaxy
    @galaxies << galaxy
  end
end

end
