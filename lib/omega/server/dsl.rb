# Omega Server DSL
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos'
require 'manufactured'

module Omega
  module Server

    # Omega Server DSL, works best if you including this module in the
    # namespace you would like to use it, eg:
    #
    # @example using the dsl
    #   include Omega::Client::DSL
    #
    #   # require privileges
    #   require_privilege 'create', 'locations'
    #
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
        session.message_headers['session_id'] = session.id
        session
      end

      # Return bool indicating if node is of given type
      def is_node?(type)
        @rjr_node_type == type::RJR_NODE_TYPE
      end

      # Require privileges using the local users registry
      def require_privilege(args = {})
        rargs = args.merge(:session => @headers['session_id'])
        Users::Registry.require_privilege rargs
      end

      # Check privileges using the local users registry
      def check_privilege(args = {})
        rargs = args.merge(:session => @headers['session_id'])
        Users::Registry.check_privilege rargs
      end

      # Filter properties able / not able to be set by the end user
      def filter_properties(data, filter = {})
        ndata = data.class.new
        if filter[:allow]
          # copy allowed attributes over
          filter[:allow].each { |a|
            ndata.send("#{a}=".intern, data.send(a.intern))
          }

        else
          # TODO copy all attributes over

        end

        # if filter[:reject] TODO

        return ndata
      end

      # Return a filter constructed from the specified args
      def filter_from_args(args, matchers)
        filters = []
        nargs   = Array.new(args)
        while arg = nargs.shift
          matcher = matchers.find { |k,v| k == arg }
          raise ValidationError, "invalid filter #{arg}" if matcher.nil?
          matcher = matcher.last

          params  = []
          nparams = match.arity - 1 # assume first param is for entity
          0.upto(nparams - 1) {
            params << nargs.shift
          } if nparams > 0

          filters << proc { |e| matcher.call *([e] + params) }
        end

        filters
      end

    end
  end
end
