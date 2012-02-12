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

  def find_entity(type, id)
    return self if type == :universe

    @galaxies.each { |g|
      return g if type == :galaxy && id == g.id
      g.solar_systems.each { |sys|
        return sys if type == :solar_system && id == sys.id
        return sys.star if type == :star && id == sys.star.id
        sys.planets.each { |p|
          return p if type == :planet && id == p.id
          p.moons.each { |m|
            return m if type == :moon && id == m.id
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
