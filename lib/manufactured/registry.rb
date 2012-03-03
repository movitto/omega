# Manufactured entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured

class Registry
  include Singleton
  attr_accessor :ships
  attr_accessor :stations
  attr_accessor :fleets

  def initialize
    @ships    = []
    @stations = []
    @fleets   = []
  end

  def find(args = {})
    id = args[:id]
    parent_id = args[:parent_id]

    entities = []

    [@ships, @stations, @fleets].each { |entity_array|
      entity_array.each { |entity|
        entities << entity if (id.nil? || entity.id == id) &&
                              (parent_id.nil? || entity.parent.id == parent_id)

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

end

end
