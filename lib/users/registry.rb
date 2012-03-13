# Users entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'singleton'

module Users

class Registry
  include Singleton
  # user entities registry
  attr_accessor :users
  attr_accessor :alliances

  # user sessions registry
  attr_accessor :sessions

  def initialize
    @users     = []
    @alliances = []
    @sessions  = []
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

  def create_session(user)
    # TODO just return user session if already existing
    session = Session.new :user => user
    @sessions << session
    return session
  end

  def destroy_session(session_id)
    @sessions.delete_if { |session| session.id == session_id }
  end

end

end
