# Omega Client Node
#   Singleton server access point
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users'
require 'manufactured'
require 'cosmos'
require 'motel'

require 'singleton'

module Omega
  module Client

    # Provides mechanism to cache entity attributes to be periodically
    # updated via specified callbacks
    class CachedAttribute

      # The default cache timeout in seconds, after which 
      # registered callback is invoked. Currenty 1/2 minute
      TIMEOUT = 30

      # Define an attribute accessor method which stores a local
      # copy of the attribute for TIMEOUT seconds after
      # which invoking the command specied by the given block.
      #
      # The current value of the attribute will be passed as the only argument
      # to the block. After the block is invoke the timeout for the
      # entity attribute is reset
      #
      # @example
      #   ship = Node.invoke_request('manufactured::get_entity', 'with_id', 'ship1')
      #   CachedAttribute.cache(ship, :location) { |l|
      #     Node.invoke_request('motel::get_location', 'with_id', l.id)
      #   }
      #
      # @param [Object] entity entity whose attribute we are caching
      # @param [Symbol] attribute entity attribute being updated
      # @param [Callable] callback block parameter to be invoked after timeout
      def self.cache(entity, attribute, &callback)
        CachedAttribute.cached(entity, attribute,
                               entity.send(attribute.intern)) if entity.class.method_defined?(attribute.intern)

        entity.eigenclass.send(:define_method, attribute.intern){
          te   = CachedAttribute.enabled?
          ts   = CachedAttribute.timestamp(self.id, attribute)
          orig = CachedAttribute.cached(entity, attribute)

          if te && (ts.nil? || (Time.now - ts) > TIMEOUT)
            CachedAttribute.timestamp(self.id, attribute, Time.now)
            CachedAttribute.cached(entity, attribute,
                                   instance_exec(orig, &callback))
          end
          self.instance_variable_get("@cached_#{attribute}")
        }
      end

      # Global enable command flag, defaults to true, set to false
      # to always use local cached copy. May be specified w/out param,
      # will always return value of the flag.
      #
      # @param  [true,false] val optional value to assign to flag
      # @return [true,false] value of the flag
      def self.enabled?(val=nil)
        @enabled = true if @enabled.nil? # TODO default false?
        @enabled = val unless val.nil?
        @enabled
      end


      #######################################################################
      # private method, end user should not invoke:

      # Global timestamp registry, set the time the specified attribute
      # for the specified entity was updated. May be called w/out param, will
      # always return the timestamp for the specified attribute
      #
      # Shouldn't be called by the end user.
      #
      #
      # @param [String] entity_id id of the entity whose attribute is being updated
      # @param [Symbol] attribute entity attribute being updated
      # @param [Time] val option timestamp to register
      # @return [Time] timestamp in registry entity for entity/attribute
      def self.timestamp(entity_id, attribute, new_val=nil)
        @timestamps ||= {}
        @timestamps[entity_id.to_s + '-' + attribute.to_s] = new_val unless new_val.nil?
        @timestamps[entity_id.to_s + '-' + attribute.to_s]
      end

      # Global cached attribute registry, set the cached value of the
      # entity attribute. May be called w/out value, will always return
      # the cached value of the attribute
      #
      # Shouldn't be called by the end user.
      #
      # @param [String] entity_id id of the entity whose attribute is being updated
      # @param [Symbol] attribute entity attribute being updated
      # @param [Array<Object>] args optional, additional arguments will be captured,
      #   though only the first will be used to set the cached attribute
      # @return [Object] the value of the cached attribute
      def self.cached(entity, attribute, *args)
        entity.instance_variable_set("@cached_#{attribute}", args.first) if args.size == 1
        entity.instance_variable_get("@cached_#{attribute}")
      end
    end

    # The Client Node representing a singleton interface which to get and
    # set local copies of server side entities, invoke requests via a registered
    # rjr node, and handle/raise events on those entities
    class Node
      class << self
        # @!group Config options

        # String server endpoint which to send requests to
        # @!scope class
        attr_accessor :server_endpoint

        # Integer seconds which to wait inbetween checking for new events
        # @!scope class
        attr_accessor :refresh_time

        # Username to use to login to server
        # @!scope class
        attr_accessor :client_username

        # Password to use to login to server
        # @!scope class
        attr_accessor :client_password
      end

      # Node subsystem
      def initialize(args = {})
        @registry       = {}
        @event_handlers = {}
        @refresh_list   = {}
        @event_queue    = Queue.new
        @lock           = Mutex.new
      end

      # Set the RJR::Node used to communicated w/ the server.
      # This method uses the node to start listening for notification
      # callbacks and to log into the server using the configured credentials
      #
      # @param [RJR::Node] node rjr node subclass to use as transport
      def node=(node)
Omega::Client::Node.refresh_time = 1
        # set default server endpoint depending on node type
        Omega::Client::Node.server_endpoint =
          case node.class::RJR_NODE_TYPE
            when :amqp then 'omega-queue'
            when :tcp  then 'json-rpc://localhost:8181'
            else nil
          end

        @node = node
        @node.message_headers['source_node'] = @node.node_id
        @node.listen

        @user =
          Users::User.new(:id => Omega::Client::Node.client_username,
                          :password => Omega::Client::Node.client_password)
        @session = self.invoke_request('users::login', @user)
        @node.message_headers['session_id'] = @session.id
                    
        @node
      end

      # Return logged in user
      # @return [Users::User] user logged into server
      def user
        @user
      end

      include Singleton

      # Permits singleton instance methods to be
      # invoked directly on class
      def self.method_missing(method_id, *args, &bl)
        Node.instance.send method_id, *args, &bl
      end

      # Return local copy of server side entity corresponding to id
      # @param [String] id id of entity to retrieve
      # @return [Object] object corresponding to id, nil if not found
      def get(id)
        @lock.synchronize{
          @registry[id]
        }
      end

      # Invoke specified block selecting entities from registry
      # @param [Callable] bl block specifying selection criterial
      # @return [Array<Object>] objects in registry for which selection block returned true
      def select(&bl)
        # A local copy of registry is used so as to
        # not hold lock during iterations
        tr = Hash.new
        @lock.synchronize{
          tr.merge! @registry
        }
        tr.select(&bl)
      end

      # Register the entity in the registry. The entity's id
      # is used to track the entity locally.
      #
      # This method raises the :updated event on the entity
      #
      # @param  [Object] entity entity to add to the registry
      # @return [Object] entity added to the registry
      def set(entity)
        @lock.synchronize{
          @registry[entity.id] = entity
        }

        raise_event(:updated, entity)
        entity
      end

      # Return the entity specified by id, or if not found
      # invoke the specified block and register the entity
      # returned by it.
      #
      # @param [String] id id of the entity to retrieve, will be
      #   passed as the only parameter to the specified block
      #   if entity is not found
      # @param [Callbacks] retrieval block parameter to invoke
      #   with given if if entity is not found in the registry
      # @return [Object] object retrieved from registry
      def cached(id, &retrieval)
        entity = get(id)
        entity = retrieval.call(id) if entity.nil?
        set(entity)
      end

      # Use the RJR::Node to invoke the specified server side method
      # with the given arguments.
      #
      # All entities returned by this request will be added to the
      # local registry.
      #
      # @param [String] method to invoke on the server
      # @param [Array<Object>] args all other arguments will be passed to server
      # @return [Object] object returned by server, note if server raises an exception,
      #   this will not return (exception will be reraised)
      def invoke_request(method, *args)
        args = convert_invoke_args(args)
        args.unshift method
        args.unshift Omega::Client::Node.server_endpoint unless Omega::Client::Node.server_endpoint.nil?
        res = nil
        @lock.synchronize {
          res = @node.invoke_request *args
        }

        set_result(res)
        res
      end

      # Register jsonrpc method to be handled by the local node.
      #
      # Methods are captured and raised as an event on the entity
      # detected from the event args.
      #
      # All entities specified in the method request will be added to the
      # local registry.
      #
      # @param [String] method rjr method which to handle
      def add_method_handler(method)
        RJR::Dispatcher.add_handler(method) { |*args|
          Node.set_result(args)
          Node.raise_event(method, *args)
        }
      end

      # Return boolean if the jsonrpc method was registered
      #
      # @param [String] method rjr method which to check for
      # @return [true,false] indiciting if method was registered
      def has_method_handler_for?(method)
        RJR::Dispatcher.has_handler_for?(method)
      end

      # Clear method handlers
      def clear_method_handlers!
        RJR::Dispatcher.clear!
      end


      # Add the specified event to the event queue. Starts up
      # the event processor if it is not already running.
      #
      # The event processor will sequentially run through
      # the events, extracting the entity id from the args,
      # and invoke the handler registered for the entity/event
      # (if any)
      #
      # @param [Symbol] method identifier of the event being raised
      # @param [Array<Object>] all additional params are captured and
      #   registered with event
      def raise_event(method, *args)
        @event_queue.push([method, args])

        # FIXME simplify, we don't need an external loop
        @lock.synchronize{
          return if @event_cycle
          @event_cycle = true

          @node.em_repeat_async(Omega::Client::Node.refresh_time) {
            while @event_queue.size > 0 && event = @event_queue.pop
              method,args = event.first,event.last
              entity_id = id_from_event_args(args)  # extract id
              @event_handlers[entity_id][method].each { |cb|
                cb.call(*args)
              } if @event_handlers[entity_id] && @event_handlers[entity_id][method]
            end
          }
        }
      end

      # Register the block to be invoked upon the specified event
      # being raised for the specified entity.
      #
      # The parameters passed to the event will be passed to the
      # callback handler upon invocation.
      #
      # @param [String] entity_id id of the entity which to register event handler
      # @param [Symbol] event event which to invoke block upon detection
      # @param [Callable] bl block param to be invoked w/ event args upon
      #   detecting event
      def add_event_handler(entity_id, event, &bl)
        @lock.synchronize {
          @event_handlers[entity_id]        ||= {}
          @event_handlers[entity_id][event] ||= []
          @event_handlers[entity_id][event] << bl
        }
      end

      ########################################################################
      # XXX these are the hacky/glue methods that smoothing things out on a
      # case by case basis:

      # Global catch all for parameters detected from serverside request results
      # and local rjr method invokations by the server. Adds all parameters
      # to lcal registry.
      #
      # Additional options performed:
      # * The locations of all planets are cached using CachedAttribute
      # * The resource_sources of all asteroids are cached using CachedAttribute
      # * The solar system corresponding to manufactured entities are assigned
      #   from the local copies and if those don't exist, are retrieved from
      #   the server
      #
      # @param [Object,Array<Object>] res object or array of objects, if any of
      #   which are detected as belonging to on of the Omega subsystems, will
      #   be added to the local registry.
      def set_result(res)
        if(res.is_a?(Array))
          res.each { |r| set_result(r) }

        elsif Cosmos::Registry.instance.entity_types.include?(res.class) &&
              !res.is_a?(Cosmos::JumpGate)
          set(res)
          set(res.location)
          if(res.is_a?(Cosmos::SolarSystem))
            res.planets.each   { |pl|
              set(pl)
              CachedAttribute.cache(pl, :location) { |l|
                Node.invoke_request('motel::get_location', 'with_id', l.id)
              }
            }
            res.asteroids.each { |ast|
              #set(ast)
              CachedAttribute.cache(ast, :resource_sources) { |rs|
                Node.invoke_request('cosmos::get_resource_sources', self.name)
              }
            }
            #res.jump_gates.each { |gate|
            #  gate.endpoint = cached(gate.endpoint)
            #}
          end

        elsif Manufactured::Registry.instance.entity_types.include?(res.class)
          set(res)
          set(res.location)
          res.solar_system = cached(res.system_name) { |id|
            invoke_request 'cosmos::get_entity',
                  'with_name', res.system_name
          }

        elsif Users::Registry::VALID_TYPES.include?(res.class) ||
              res.is_a?(Motel::Location)
          set(res)

        end
      end

      private

      # Retrieve the target entity id from the event args.
      def id_from_event_args(args)
        # XXX Right now does this rather simply, returns the id of the
        # first Cosmos/Manufactured/Users entity it finds, or if
        # a location is specified, the id of the entity corresponding
        # to that. We might want to make this smarter at some point
        types = Cosmos::Registry.instance.entity_types       +
                Manufactured::Registry.instance.entity_types +
                Users::Registry::VALID_TYPES

        e = args.find { |e| types.include?(e.class) ||
                              (e.class.respond_to?(:entity_type) &&
                               types.include?(e.class.entity_type)) }
        if e.nil? && args.first.is_a?(Motel::Location)
          e = self.select { |eid,e|
            (types.include?(e.class) ||
             (e.class.respond_to?(:entity_type) &&
              types.include?(e.class.entity_type))) &&
            (e.respond_to?(:location) && e.location &&
             e.location.id == args.first.id)
          }.first
          e = e.last unless e.nil?
        end

        return nil if e.nil?

        e.id
      end

      # Smoothen out parameters to be sent to server
      def convert_invoke_args(args)
        args.collect { |a|
          if a.is_a?(Cosmos::JumpGate)
            if a.solar_system.is_a?(Omega::Client::SolarSystem)
              a.solar_system = a.solar_system.name
            end

            if a.endpoint.is_a?(Omega::Client::SolarSystem)
              a.endpoint = a.endpoint.name
            end

          elsif a.is_a?(Manufactured::Ship) || a.is_a?(Manufactured::Station)
            if a.solar_system.is_a?(Omega::Client::SolarSystem)
              a.solar_system = get(a.solar_system.name)
            end
          end

          a
        }
      end

    end
  end
end
