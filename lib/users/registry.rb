# Users entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/exceptions'

require 'singleton'

module Users

class Registry
  include Singleton

  # valid types this registry tracks
  VALID_TYPES = [Users::User, Users::Alliance]

  # user entities registry
  def users
    u = []
    @entities_lock.synchronize{
      u = @users.collect { |user| user }
    }
    u
  end

  def alliances
    a = []
    @entities_lock.synchronize{
      a = @alliances.collect { |alliance| alliance }
    }
    a
  end

  # user sessions registry
  attr_accessor :sessions

  def initialize
    init
  end

  def init
    @users     = []
    @alliances = []
    @sessions  = []

    @entities_lock = Mutex.new
  end

  def find(args = {})
    id        = args[:id]
    type      = args[:type]
    session_id = args[:session_id]
    registration_code = args[:registration_code]

    session = session_id.nil? ? nil : @sessions.find { |s| s.id == session_id }

    entities = []

    to_search = []
    @entities_lock.synchronize {
      to_search = [@users, @alliances].flatten
    }

    to_search.each { |entity|
      entities << entity if (id.nil?        || (entity.id         == id)) &&
                            (type.nil?      || (entity.class.to_s == type)) &&
                            (session.nil?   || (entity.is_a?(Users::User) && session.user.id   == entity.id)) &&
                            (registration_code.nil? || (entity.is_a?(Users::User) && entity.registration_code == registration_code))
    }
    entities
  end

  def create(entity)
    @entities_lock.synchronize{
      if entity.is_a?(Users::User)
        existing = @users.find { |u| u.id == entity.id }
        if existing.nil?
          entity.created_at = Time.now
          entity.last_modified_at = Time.now
          @users     << entity
        else # raise exception?
          entity = existing
        end

      elsif entity.is_a?(Users::Alliance)
        existing = @alliances.find { |a| a.id == entity.id}
        if existing.nil?
          @alliances << entity
        else
          entity = existing
        end

      end
    }
    entity
  end

  def remove(id)
    @entities_lock.synchronize{
      entity = nil
      [@users, @alliances].each { |entitya|
        entity = entitya.find { |entity| entity.id == id }
        unless entity.nil?
          entitya.delete(entity)

          # if removing user, remove sessions
          if entity.is_a?(Users::User)
            destroy_session(:user_id => entity.id)
          end
        end
      }
    }
  end

  def create_session(user)
    # just return user session if already existing
    session = @sessions.find { |s| s.user_id == user.id }
    return session unless session.nil?

    user.last_login_at = Time.now
    session = Session.new :user => user
    @sessions << session
    return session
  end

  def destroy_session(args = {})
    @sessions.delete_if { |session|
      session.id == args[:session_id] ||
      session.user.id == args[:user_id]
    }
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

  def self.check_privilege(args = {})
    self.instance.check_privilege(args)
  end

  def check_privilege(args = {})
    begin
      require_privilege(args)
    rescue Omega::PermissionError
      return false
    end
    return true
  end

  def self.current_user(args = {})
    self.instance.current_user(args)
  end

  def current_user(args = {})
    session_id = args[:session]

    session = @sessions.find { |s| s.id == session_id }
    return nil if session.nil?
    session.user
  end

  # Save state of the registry to specified stream
  def save_state(io)
    # TODO block new operations on registry
    users.each { |user|
      user.secure_password = false
      io.write user.to_json + "\n"
      user.secure_password = true

      user.privileges.each { |priv|
        io.write priv.to_json + "\n"
      }
    }

    alliances.each { |alliance|
      io.write alliance.to_json + "\n"
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

      elsif entity.is_a?(Users::Alliance)
        create(entity)
      end
    }
  end

end

end
