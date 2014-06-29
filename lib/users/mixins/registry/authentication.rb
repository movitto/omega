# Users Authentication Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'

module Users
module Authentication
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

  # Wrapper around {#check_privilege} that raises error
  # if user does not have privilege
  #
  # Takes same parameter list as {#require_privilege}
  # @raise [Omega::PermissionError] if none of the
  #   specified privileges can be found
  def require_privilege(args = {})
    unless check_privilege(args)
      log_args = args.reject { |k,v| k == :registry }.inspect
      err = "require_privilege(#{log_args}): user does not have required privilege"

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

    log_args = args.reject { |k,v| k == :registry }.inspect

    session = entities { |e| e.is_a?(Session) && e.id == session_id }.first
    if session.nil?
      ::RJR::Logger.warn "check_privilege(#{log_args}): session not found"
      return false
    end

    if session.timed_out?
      destroy_session :session_id => session.id
      ::RJR::Logger.warn "check_privilege(#{log_args}): session timeout"
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
end # module Authentication
end # module Users
