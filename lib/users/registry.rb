# Users entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/exceptions'

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
    session_id = args[:session_id]
    registration_code = args[:registration_code]

    session = session_id.nil? ? nil : @sessions.find { |s| s.id == session_id }

    entities = []

    [@users, @alliances].each { |entity_array|
      entity_array.each { |entity|
        entities << entity if (id.nil?        || (entity.id         == id)) &&
                              (session.nil?   || (entity.is_a?(Users::User) && session.user.id   == entity.id)) &&
                              (registration_code.nil? || (entity.is_a?(Users::User) && entity.registration_code == registration_code))
      }
    }
    entities
  end

  def create(entity)
    if entity.is_a?(Users::User)
      @users     << entity if @users.find { |u| u.id == entity.id }.nil?

    elsif entity.is_a?(Users::Alliance)
      @alliances << entity if @alliances.find { |a| a.id == entity.id}.nil?

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

  def self.require_privilege(*args)
    self.instance.require_privilege(*args)
  end

  # TODO incorporate session privilege checks into a larger generic rjr ACL subsystem (allow generic acl validation objects to be registered for each handler)
  def require_privilege(args = {})
    session_id    = args[:session]
    privilege_ids = args[:privilege].to_a
    entity_ids    = args[:entity].to_a

    args[:any].to_a.each{ |pe|
      privilege_ids << pe[:privilege]
      entity_ids    << pe[:entity]
    }

    session = @sessions.find { |s| s.id == session_id }
    # TODO incorporate a session timeout (only if inactivity?)
    if session.nil?
      RJR::Logger.warn "require_privilege(#{args.inspect}): session not found"
      raise Omega::PermissionError, "session not found"
    end

    found_priv = false
    0.upto(privilege_ids.size){ |pi|
      privilege_id = privilege_ids[pi]
      entity_id    = entity_ids[pi]

      if (entity_id != nil && session.user.has_privilege_on?(privilege_id, entity_id)) ||
         (entity_id == nil && session.user.has_privilege?(privilege_id))
           found_priv = true
           break
      end
    }
    unless found_priv
      # TODO also allow for custom error messages
      RJR::Logger.warn "require_privilege(#{args.inspect}): user does not have required privilege"
      raise Omega::PermissionError, "user #{session.user.id} does not have required privilege #{privilege_ids.join(', ')} " + (entity_ids.size > 0 ? "on #{entity_ids.join(', ')}" : "")
    end
  end

  # Save state of the registry to specified stream
  def save_state(io)
    # TODO block new operations on registry
    users.each { |user|
      io.write user.to_json + "\n"
      user.privileges.each { |priv|
        io.write priv.to_json + "\n"
      }
    }
  end

  # restore state of the registry from the specified stream
  def restore_state(io)
    prev_entity = nil
    io.each { |json|
      entity = JSON.parse(json)
      if entity.is_a?(Users::User)
        create(entity)
        prev_entity = entity
      elsif entity.is_a?(Users::Privilege)
        prev_entity.add_privilege(entity)
      end
    }
  end

end

end
