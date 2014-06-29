# Users Manages Sessions Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Users
module ManagesSessions
  # Return session for the specified user, if none exists create one first
  #
  # @param [Users::User] user which to create the session for
  # @param [String] source_node id of rjr node which this
  #   session was established on
  def create_session(user, source_node)
    # just return user session if already existing
    session = self.entities { |e|
      e.is_a?(Session) && e.user.id == user.id
    }.first

    # remove session if timed out
    if !session.nil? && session.timed_out?
      destroy_session :session_id => session.id
      session = nil
    end

    # FIXME update endpoint_id if session not nil
    return session unless session.nil?

    user.last_login_at = Time.now
    session = Session.new :user           => user,
                          :refreshed_time => user.last_login_at,
                          :endpoint_id    => source_node
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

  # Return the {Users::User} corresponding to the specified active session id
  # If session has expired, it is invalided and nil is returned
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

  # Return the active {Users::Session} cooresponding to the specified id.
  # If session has expired, it is invalidated and nil is returned
  #
  # @param [Hash] args options to use to lookup session
  # @option args [String] :id id of the session to lookup
  # @return [Users::Session,nil] session corresponding to id or nil
  #   if not found or exipired
  def current_session(args = {})
    session_id = args[:id]

    session = self.entity{ |e| e.is_a?(Session) && e.id == session_id }

    return nil if session.nil?
    if session.timed_out?
      destroy_session :session_id => session.id
      return nil
    end

    session
  end
end # module ManagesSessions
end # module Users
