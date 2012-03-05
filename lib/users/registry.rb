# Users entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'singleton'

module Users

class Registry
  include Singleton
  attr_accessor :users
  attr_accessor :alliances

  def initialize
    @users     = []
    @alliances = []
  end

  def find(args = {})
    id        = args[:id]

    entities = []

    [@users, @alliances].each { |entity_array|
      entity_array.each { |entity|
        entities << entity if (id.nil?        || entity.id         == id)
      }
    }
    entities
  end

  def create(entity)
    if entity.is_a?(Users::User)
      @users << entity
    elsif entity.is_a?(Users::Alliance)
      @alliances << entity
    end
  end

end

end
