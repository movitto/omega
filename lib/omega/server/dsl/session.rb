# Omega Server DSL session operations
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
  module Server
    module DSL
      # Log a user into the specified node using the given
      # username / password
      #
      # @param [RJR::Node] node instance of rjr node or subclass to use to login the user
      # @param [String] username string id of the user to login
      # @param [String] password password of the user to login
      def login(node, username, password)
        user    = Users::User.new(:id => username, :password => password)
        session = node.invoke('users::login', user)
        node.message_headers['session_id'] = session.id
        session
      end

      # Require privileges using the specified registry
      def require_privilege(args = {})
        registry = args[:registry] || args[:user_registry]
        rargs = args.merge(:session => @rjr_headers['session_id'])
        registry.require_privilege rargs
      end

      # Check privileges using the specified registry
      def check_privilege(args = {})
        registry = args[:registry] || args[:user_registry]
        rargs = args.merge(:session => @rjr_headers['session_id'])
        registry.check_privilege rargs
      end

      # Return current logged in user using the specified registry
      def current_user(args = {})
        registry = args[:registry] || args[:user_registry]
        registry.current_user :session => @rjr_headers['session_id']
      end

      # Return the current logging session using the specified registry
      def current_session(args = {})
        registry = args[:registry] || args[:user_registry]
        registry.current_session :id => @rjr_headers['session_id']
      end

      # Raise an error if the endpoint which the session was established on
      # is not the same as the specified source node
      def validate_session_source!(args = {})
        # TODO if this is false we should invalidate session,
        # log the err, and send an email to the admin / etc
        matched = current_session(args).endpoint_id == @rjr_headers['source_node']
        err = args[:msg] || "source/session mismatch!"
        raise PermissionError, err unless matched
      end
    end # module DSL
  end # module Server
end # module Omega
