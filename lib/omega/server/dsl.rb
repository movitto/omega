# Omega Server DSL
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

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
      # Get/set node used in operations
      attr_accessor :node

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

      # Return bool indicating if node is of given type
      def is_node?(type)
        !@rjr_node.nil? && @rjr_node.node_type == type::RJR_NODE_TYPE
      end

      # Require privileges using the local users registry
      def require_privilege(args = {})
        rargs = args.merge(:session => @rjr_node.message_headers['session_id'])
        Users::Registry.instance.require_privilege rargs
      end

      # Check privileges using the local users registry
      def check_privilege(args = {})
        rargs = args.merge(:session => @rjr_node.message_headers['session_id'])
        Users::Registry.instance.check_privilege rargs
      end

      # Return current logged in user using local users registry
      def current_user
        Users::Registry.instance.
          current_user :session => @rjr_node.message_headers['session_id']
      end

      # Filter properties able / not able to be set by the end user
      def filter_properties(data, filter = {})
        ndata = data.class.new
        if filter[:allow]
          filter[:allow] = [filter[:allow]] unless filter[:allow].is_a?(Array)
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

      # Return a list of filters constructed from the specified args
      #
      # @example generating filters from args
      #   def get_data(*args)
      #     filters = 
      #       filters_from_args args,
      #         :with_id   => proc { |e, id| e.id == id },
      #         :between   => proc { |e, lval, gval|
      #           e.value < gval && e.value > lval
      #         }
      #
      #      return my_entities.all? { |e| filters.all? { |f| f.call(e) } }
      #    end
      #
      #    get_data(:with_id, 'foo')
      #    get_data(:with_id, 'bar',
      #             :between, 0, 5)
      #    get_data(:with_property, "foobar")
      #    #=> raises error since "with_property" not defined
      def filters_from_args(args, allowed_filters)
        filters = []

        # create copy of args list so as to modify
        nargs   = Array.new(args)

        # shift first argument of from list (the filter id)
        while arg = nargs.shift

          # find the filter with the same key as the filter id
          filter = allowed_filters.find { |k,v| k.to_s == arg.to_s }

          # raise error if it could not be found
          raise ValidationError, "invalid filter #{arg}" if filter.nil?
          filter = filter.last

          # shift number of arguments off list corresponding to the
          # arity of the filter method (minus one, assume first param
          # is for the entity to match with the filter)
          params  = []
          nparams = filter.arity - 1 # 
          0.upto(nparams - 1) {
            params << nargs.shift
          } if nparams > 0

          # addd a procedure calling the filter with the 
          # specified entity and parameter list to the filter list
          filters << proc { |e| filter.call *([e] + params) }
        end

        filters
      end

      # Generate a selector which matches entity w/ specified id
      def with_id(eid)
        proc { |e| e.id == eid }
      end

      # Generate a selector

    end
  end
end