# Omega Server DSL
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/command'

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

      # Require rjr node of the specified type, else raise a permission err
      # TODO
      #def require_node!(type)
      #end

      # Return bool indicating if request has come in over a persistent transport
      def persistent_transport?
        @rjr_node.persistent?
      end

      # Raise error is transport is not persistent
      def require_persistent_transport!(err=nil)
        err = "request must come in on persistent transport" if err.nil?
        raise OperationError, err unless persistent_transport?
      end

      # Return bool indiciating if source node is valid / can be used by Omega
      def from_valid_source?
         @rjr_headers['source_node'].is_a?(String) &&
        !@rjr_headers['source_node'].empty?
      end

      # Raise error if source node is not valid
      def require_valid_source!(err=nil)
        err = "source node is required" if err.nil?
        raise PermissionError, err unless from_valid_source?
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

      # Check if the user has the specified attribute
      def check_attribute(args = {})
        query = 'users::has_attribute?', args[:user_id], args[:attribute_id]
        query << args[:level] if args.has_key?(:level)
        args[:node].invoke(*query)
      end

      # Require the user to have the specified attribute, else raise PermissionErr
      def require_attribute(args = {})
        raise Omega::PermissionError,
          "require_attribute(#{args})" unless check_attribute(args)
      end

      # Filter properties able / not able to be set by the end user
      def filter_properties(data, filter = {})
        is_hash = data.is_a?(Hash)
        ndata   = is_hash ? {} : data.class.new
        if filter[:allow]
          filter[:allow] = [filter[:allow]] unless filter[:allow].is_a?(Array)
          # copy allowed attributes over
          filter[:allow].each { |a|
            if is_hash
              ndata[a.intern] = data[a.intern] || data[a.to_s]
            else
              ndata.send("#{a}=".intern, data.send(a.intern))
            end
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
          # XXX need to define/call an inline function to bind filter/params variables
          filters << proc { |f,p| proc { |e| f.call e, *p } }.call(filter, params)
        end

        filters
      end

      # Require entity to be in the state specified by the given callback.
      # Raise ValidationError otherwise
      def require_state(entity, msg=nil, &validation)
        unless validation.call entity
          msg ||= "#{entity} did not pass validation"
          raise ValidationError, msg
        end
      end

      # Generate a selector from block which is called to determine selection
      def matching(&bl)
        proc { |e| bl.call(e) }
      end

      # Generate a selector which compares entity w/ specified attribute
      def with(attr, val)
        proc { |e| e.respond_to?(attr.intern) && e.send(attr.intern) == val }
      end

      # Generate a selector which matches entity w/ specified id
      def with_id(eid)
        with(:id, eid)
      end

      # Generate a selector which matches entities _not_
      # descending from the Omega::Server namespace
      def in_subsystem
        proc { |e|
          !e.class.ancestors.any? { |cl|
            cl.to_s =~ /Omega::Server::.*/
          }
        }
      end

      # Return boolean indicating if specified entity is a command
      def is_cmd?(entity)
        entity.kind_of?(Omega::Server::Command)
      end

      # Helper to delete event handler in registry for event/endpoint
      def delete_event_handler_for(args={})
        event_id    = args[:event_id]
        event_type  = args[:event_type]
        endpoint_id = args[:endpoint_id]
        registry    = args[:registry]
      
        registry.delete { |entity|
          entity.is_a?(Omega::Server::EventHandler) &&
          (event_id.nil?   || entity.event_id   == event_id) &&
          (event_type.nil? || entity.event_type == event_type) &&
          entity.endpoint_id == endpoint_id
        }
      end
    end
  end
end
