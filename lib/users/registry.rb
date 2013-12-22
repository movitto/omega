# Users entity registry
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'users/session'
require 'omega/server/registry'
require 'omega/server/event'

module Users

# Primary server side entity tracker for the Users module.
#
# Provides a thread safe registry through which users can be accessed and managed.
#
# Also provides thread safe methods which to query users and privileges
# based on a session id and other parameters
#
# Singleton class, access via Users::Registry.instance.
class Registry
  include Omega::Server::Registry

  class << self
    # @!group Config options

    # Boolean toggling if user permission system is enabled / disabled.
    # Disabling permissions will result in all require/check privileges
    # calls returning true
    #
    # TODO ideally would have this in rjr adapter like user_attributes.
    # To do this, all require/check privilege calls (as invoked by other subsystems)
    # would have to go through rjr
    attr_accessor :user_perms_enabled

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.user_perms_enabled = config.user_perms_enabled
    end

    # @!endgroup
  end

  private

  # TODO raise errors if references can't be resolved?

  def check_user(nuser, ouser=nil)
    @lock.synchronize {
      # ensure roles reference roles in registry
      ruser = @entities.find { |e|
          e.is_a?(Users::User) && e.id == nuser.id
        }
      ruser.roles.each_index { |rolei|
        ri   = ruser.roles[rolei].id
        role = @entities.find { |e| e.is_a?(Users::Role) && e.id == ri }
        ruser.roles[rolei] = role
      } unless ruser.roles.nil?
    }
  end

  def check_session(session)
    @lock.synchronize {
      # ensure session references user in registry
      rsession = @entities.find { |e|
          e.is_a?(Users::Session) && e.id == session.id
        }
      ruser = @entities.find { |e|
          e.is_a?(Users::User) && e.id == rsession.user.id
        }
      rsession.user = ruser
    }
  end

  public

  # Users::Registry intitializer
  def initialize
    init_registry

    # validate user/role id or session's user id is unique on creation
    self.validation_callback { |r,e|
      e.kind_of?(Omega::Server::Event) ||
      ([User, Role, Session].include?(e.class) &&

       (e.is_a?(Session) ?
          r.select  { |re| re.is_a?(Session)      }.
            find    { |s|  s.user.id == e.user.id }.nil? :
          r.find    { |re| re.id == e.id          }.nil?))
    }
    
    # set user timestamps on creation
    on(:added) { |e|
      if e.is_a?(User)
        e.created_at       = Time.now
        e.last_modified_at = Time.now
      end
    }

    # sanity checks on user
    on(:added)   { |e|    check_user(e)    if e.is_a?(Users::User) }
    on(:updated) { |e,oe| check_user(e,oe) if e.is_a?(Users::User) }

    # sanity checks on session
    on(:added)   { |e|    check_session(e) if e.is_a?(Users::Session) }

    # run local events
    run { run_events }
  end

  ####################### public users registry api / utility methods

  # Return boolean indicating if login credentials for the specified user are valid
  #
  # @param [String] user_id id of user to lookup
  # @param [String] password password to match
  # @return [true/false] indicating if specified user id/password are valid
  def valid_login?(user_id, password)
    @lock.synchronize {
      user = @entities.find { |e| e.is_a?(User) && e.id == user_id }
      return false if user.nil?
      user.valid_login?(user_id, password)
    }
  end

  # Return session for the specified user, if none exists create one first
  #
  # @param [Users::User] user which to create the session for
  def create_session(user)
    # just return user session if already existing
    session = self.entities { |e|
      e.is_a?(Session) && e.user.id == user.id
    }.first

    # remove session if timed out
    if !session.nil? && session.timed_out?
      destroy_session :session_id => session.id
      session = nil
    end

    return session unless session.nil?

    user.last_login_at = Time.now
    session = Session.new :user => user, :refreshed_time => user.last_login_at
    self << session
    return session
  end

  # Destroy the session specified by the given args
  #
  # @param [Hash] args hash of options to use to lookup sessions to delete
  # @option [String] session_id id of the session to delete
  # @option [String] user_id id of the user to delete sessions for
  def destroy_session(args = {})
    self.delete { |e|
      e.is_a?(Session) &&
      (e.id      == args[:session_id] ||
       e.user.id == args[:user_id])
    }
  end

  # Wrapper around {#check_privilege} that raises error
  # if user does not have privilege
  #
  # Takes same parameter list as {#require_privilege}
  # @raise [Omega::PermissionError] if none of the
  #   specified privileges can be found
  def require_privilege(args = {})
    unless check_privilege(args)
      err = "require_privilege(#{args.inspect}): user does not have required privilege"

      # TODO custom error messages
      ::RJR::Logger.warn err
      raise Omega::PermissionError, err
    end
  end

  # Return true/false indicating if user correspoding to
  # current session has specified privileges
  #
  # @param [Hash] args hash of options to use in permission check
  # @option args [String] :session id of session to use to lookup user
  # @option args [String] :privilege id of privilege which to check on user
  # @option args [String] :entity id or of entity corresponding to privilege to check
  # @option args [Array<Hash<Symbol,String>>] :any array of hashes containing :privilege and :entity attributes
  #   corresponding to ids of privileges and corresponding entities to look for.
  #   So long as the user has *at least one* of these privilege / entity pairs,
  #   true will be returned
  # @return [true,false] indicating if user has / does not have privilege
  def check_privilege(args = {})
    return true unless Registry.user_perms_enabled

    # TODO incorporate session privilege checks into a larger generic rjr ACL subsystem (allow generic acl validation objects to be registered for each handler)
    session_id    = args[:session]
    privilege_ids = Array(args[:privilege])
    entity_ids    = Array(args[:entity])

    args[:any].to_a.each{ |pe|
      privilege_ids << pe[:privilege]
      entity_ids    << pe[:entity]
    }

    session = entities { |e| e.is_a?(Session) && e.id == session_id }.first
    if session.nil?
      ::RJR::Logger.warn "check_privilege(#{args.inspect}): session not found"
      return false
    end

    if session.timed_out?
      destroy_session :session_id => session.id
      ::RJR::Logger.warn "check_privilege(#{args.inspect}): session timeout"
      return false
    end

    0.upto(privilege_ids.size-1){ |pi|
      privilege_id = privilege_ids[pi]
      entity_id    = entity_ids[pi]

      if (entity_id != nil && session.user.has_privilege_on?(privilege_id, entity_id)) ||
         (entity_id == nil && session.user.has_privilege?(privilege_id))
           return true
      end
    }

    return false
  end

  # Return the {Users::User} corresponding to the specified session
  #
  # @param [Hash] args session args which to lookup the user with
  # @option args [String] :session id of the session to lookup corresponding user for
  # @return [Users::User,nil] user corresponding to session or nil if not found or session timed out
  def current_user(args = {})
    session_id = args[:session]

    session = self.entities{ |e| e.is_a?(Session) && e.id == session_id }.first

    return nil if session.nil?
    if session.timed_out?
      destroy_session :session_id => session.id
      return nil
    end

    session.user
  end
end # class Registry
end # module Users
