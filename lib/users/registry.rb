# Users entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/exceptions'

require 'singleton'

module Users

# Primary server side entity tracker for the Users module.
#
# Provides a thread safe registry through which users and alliances
# can be accessed and managed.
#
# Also provides thread safe methods which to query users and privileges
# based on a session id and other parameters
#
# Singleton class, access via Users::Registry.instance.
class Registry
  include Singleton

  # Return array of classes of users types
  VALID_TYPES = [Users::User, Users::Alliance, Users::Role]

  # Return array of users tracked by this registry
  # @return [Array<Users::User>]
  def users
    u = []
    @entities_lock.synchronize{
      u = @users.collect { |user| user }
    }
    u
  end

  # Return array of alliances tracked by this registry
  # @return [Array<Users::Allianes>]
  def alliances
    a = []
    @entities_lock.synchronize{
      a = @alliances.collect { |alliance| alliance }
    }
    a
  end

  # Return array of roles tracked by this registry
  def roles
    r = []
    @entities_lock.synchronize {
      r = @roles.collect { |role| role }
    }
    r
  end

  # [Array<Users::Session>] session tracked by this registry
  attr_accessor :sessions

  # Users::Registry intitializer
  def initialize
    init
  end

  # Reinitialize the Users::Registry.
  #
  # Clears all local tracker arrays.
  def init
    @users     = []
    @alliances = []
    @roles     = []
    @sessions  = []

    @entities_lock = Mutex.new
  end

  # Run the specified block of code as a protected operation.
  #
  # This should be used when updating any users entities outside the scope of
  # registry operations to protect them from concurrent access.
  #
  # @param [Array<Object>] args catch-all array of arguments to pass to blcok on invocation
  # @param [Callable] bl block to invoke
  def safely_run(*args, &bl)
    @entities_lock.synchronize {
      bl.call *args
    }
  end

  # Lookup and return entities in registry.
  #
  # By default, with no arguments, returns a flat list of all entities
  # tracked by the registry. Takes a hash of arguments to filter entities
  # by.
  #
  # @param [Hash] args arguments to filter manufatured Users with
  # @option args [String] :id string id to match
  # @option args [String] :type string class name of entities to match
  # @option args [String] :session_id string session id of user to return
  # @option args [String] :registration_code string registration_code of user to return
  # @option args [Array<String,String>] :with_privilege array containing id and entity_id of privilege to match. Users having this privilege will be returned
  # @return [Array<Users::User,Users::Alliance>] matching entities found
  def find(args = {})
    id        = args[:id]
    type      = args[:type]
    session_id = args[:session_id]
    registration_code = args[:registration_code]
    privilege = args[:with_privilege]

    session = session_id.nil? ? nil : @sessions.find { |s| s.id == session_id }

    entities = []

    to_search = []
    @entities_lock.synchronize {
      to_search = [@users, @alliances,@roles].flatten
    }

    to_search.each { |entity|
      entities << entity if (id.nil?        || (entity.id         == id)) &&
                            (type.nil?      || (entity.class.to_s == type)) &&
                            (session.nil?   || (entity.is_a?(Users::User) && session.user.id   == entity.id)) &&
                            (registration_code.nil? || (entity.is_a?(Users::User) && entity.registration_code == registration_code)) &&
                            (privilege.nil? || (entity.is_a?(Users::User) && entity.has_privilege_on?(privilege.first, privilege.last)))
    }
    entities
  end

  # Add child users entity to registry
  #
  # Performs basic checks to ensure entity can added to registry
  # before adding to appropriate array
  #
  # @param [Users::User,Users::Alliance] entity entity to add to registry
  # @return the specified entity
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

      elsif entity.is_a?(Users::Role)
        existing = @roles.find { |r| r.id == entity.id}
        if existing.nil?
          @roles << entity
        else
          entity = existing
        end

      end
    }
    entity
  end

  # Remove entitiy specifed by id from the registry
  #
  # @param [String] id id of entity to remove from the registry
  def remove(id)
    @entities_lock.synchronize{
      entity = nil
      [@users, @alliances, @roles].each { |entitya|
        entity = entitya.find { |entity| entity.id == id }
        unless entity.nil?
          entitya.delete(entity)

          # if removing user, remove sessions
          if entity.is_a?(Users::User)
            destroy_session(:user_id => entity.id)
          elsif entity.is_a?(Users::Role)
            # TODO delete roles from users
            # @users.each
          end
        end
      }
    }
  end

  # Return session for the specified user, if none exists create one first
  #
  # @param [Users::User] user which to create the session for
  def create_session(user)
    # just return user session if already existing
    session = @sessions.find { |s| s.user_id == user.id }
    return session unless session.nil?

    user.last_login_at = Time.now
    session = Session.new :user => user
    @sessions << session
    return session
  end

  # Destroy the session specified by the given args
  #
  # @param [Hash] args hash of options to use to lookup sessions to delete
  # @option [String] session_id id of the session to delete
  # @option [String] user_id id of the user to delete sessions for
  def destroy_session(args = {})
    @sessions.delete_if { |session|
      session.id == args[:session_id] ||
      session.user.id == args[:user_id]
    }
  end

  # Convenience wrapper around {#require_privilege}
  def self.require_privilege(*args)
    self.instance.require_privilege(*args)
  end

  # Requires user corresponding to the specified session to have
  #   the privilege specified by the given args, raising an error
  #   if that is not the case
  #
  # @param [Hash] args hash of options to use in permission check
  # @option args [String] :session id of session to use to lookup user
  # @option args [String] :privilege id of privilege which to check on user
  # @option args [String] :entity id or of entity corresponding to privilege to check
  # @option args [Array<Hash<Symbol,String>>] :any array of hashes containing :privilege and :entity attributes
  #   corresponding to ids of privileges and corresponding entities to look for.
  #   So long as the user has *at least one* of these privilege / entity pairs,
  #   no error will be raised.
  # @raise [Omega::PermissionError] if none of the specified privileges can be found
  def require_privilege(args = {})
    # TODO incorporate session privilege checks into a larger generic rjr ACL subsystem (allow generic acl validation objects to be registered for each handler)
    session_id    = args[:session]
    privilege_ids = Array(args[:privilege])
    entity_ids    = Array(args[:entity])

    args[:any].to_a.each{ |pe|
      privilege_ids << pe[:privilege]
      entity_ids    << pe[:entity]
    }

    session = @sessions.find { |s| s.id == session_id }
    if session.nil?
      RJR::Logger.warn "require_privilege(#{args.inspect}): session not found"
      raise Omega::PermissionError, "session not found"
    end

    if session.timed_out?
      destroy_session :session_id => session.id
      RJR::Logger.warn "require_privilege(#{args.inspect}): session timeout"
      raise Omega::PermissionError, "session timeout"
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
      # TODO also factor in a global 'disable_auth' flag
      RJR::Logger.warn "require_privilege(#{args.inspect}): user does not have required privilege"
      raise Omega::PermissionError, "user #{session.user.id} does not have required privilege #{privilege_ids.join(', ')} " + (entity_ids.size > 0 ? "on #{entity_ids.join(', ')}" : "")
    end
  end

  # Convenience wrapper around {#check_privilege}
  def self.check_privilege(args = {})
    self.instance.check_privilege(args)
  end

  # Wrapper around {#require_privilege} that catches error and
  # simply returns boolean indicating if user has / does not have privilege.
  #
  # Takes same parameter list as {#require_privilege}
  # @return [true,false] indicating if user has / does not have privilege
  def check_privilege(args = {})
    begin
      require_privilege(args)
    rescue Omega::PermissionError
      return false
    end
    return true
  end

  # Convenience wrapper around {#current_user}
  def self.current_user(args = {})
    self.instance.current_user(args)
  end

  # Return the {Users::User} corresponding to the specified session
  #
  # @param [Hash] args session args which to lookup the user with
  # @option args [String] :session id of the session to lookup corresponding user for
  # @return [Users::User,nil] user corresponding to session or nil if not found or session timed out
  def current_user(args = {})
    session_id = args[:session]

    session = @sessions.find { |s| s.id == session_id }

    return nil if session.nil?
    if session.timed_out?
      destroy_session :session_id => session.id
      return nil
    end

    session.user
  end

  # Save state of the registry to specified io stream
  def save_state(io)
    roles.each { |role|
      io.write role.to_json + "\n"
    }

    users.each { |user|
      @entities_lock.synchronize{
        io.write user.to_json + "\n"

        user.roles.each { |role|
          io.write role.to_json + "\n"
        }
      }
    }

    alliances.each { |alliance|
      io.write alliance.to_json + "\n"
    }
  end

  # restore state of the registry from the specified io stream
  def restore_state(io)
    prev_entity = nil
    io.each { |json|
      entity = JSON.parse(json)
      if entity.is_a?(Users::User)
        # FIXME secure_password will be set false, should be true
        create(entity)
        prev_entity = entity

      elsif entity.is_a?(Users::Role)
        if prev_entity
          prev_entity.add_role(entity)
          # TODO lookup role and add to user
        else
          create(entity)
        end

      elsif entity.is_a?(Users::Alliance)
        create(entity)

      end
    }
  end

end

end
