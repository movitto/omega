# Omega Client Mixins
#   Provide various high level modules which are able to be mixed into
#   classes to incorporate Omega client functionality
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/station'
require 'omega/client/node'

module Omega
  module Client
    # Include the Trackable module in classes to associate
    # instances of the class w/ server side entities.
    #
    # @example
    #   class Ship
    #     include Trackable
    #
    #     entity_type Manufactured::Ship
    #     get_method "manufactured::get_entity"
    #   end
    #
    #   Ship.get('ship1')
    module Trackable
      # @see ClassMethods
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Entity being tracked.
      attr_accessor :entity

      # Refresh entity
      def refresh
        @entity = node.invoke(self.get_method, 'with_id', id)
      end

      # By default proxy all methods to underlying entity
      def method_missing(method_id, *args, &bl)
        self.entity.send(method_id, *args, &bl)
      end

      attr_accessor :event_handlers

      # Register handler for the specified event
      #
      # @param [Symbol] event event to handle
      # @param [Array<Object>] args initialization parameters 
      # @param [Callable] handler callback to invoke on event
      def handle(event, *args, &handler)
        esetup = self.class.event_setup[event]

        esetup.each { |cb|
          self.instance_exec(*args, &cb)
        } unless esetup.nil?

        @event_handlers ||= Hash.new() { |h,k| h[k] = [] }
        @event_handlers[event] << handler unless handler.nil?
      end

      # Return bool indicating if we're handling the specified event
      def handles?(event)
        !@event_handlers.nil? && @event_handlers[event].size > 0
      end

      # Clear handlers for the specified event
      def clear_handlers_for(event)
        @event_handlers[event] = [] if @event_handlers
        # TODO we should also remove rjr notification callback from @node
      end

      # Raise event on the entity, invoke registered handlers
      def raise_event(event, *eargs)
        @event_handlers[event].each { |eh|
          begin
            eh.call self, *eargs
          rescue Exception, StandardError => e
            # TODO use logger instead?
            puts "err in #{id} #{event} handler: #{e}"
          end
            
        } if @event_handlers && @event_handlers[event]

        # run :all callbacks
        @event_handlers[:all].each { |eh|
          begin
            eh.call self, *eargs
          rescue Exception, StandardError => e
            # TODO use logger instead?
            puts "err in #{id} 'all' handler: #{e}"
          end
        } if @event_handlers && @event_handlers[:all]
      end

      # Instance wrapper around Trackable.node
      def node
        Trackable.node
      end

      # Centralized node to query / manage trackable entities
      def self.node
        @node ||= Omega::Client::Node.new
      end

      private

      # Methods that are defined on the class including 
      # the Trackable module
      module ClassMethods
        
        # Class wrapper around Trackable.node
        def node
          Trackable.node
        end

        # Define server side entity type to track
        def entity_type(type=nil)
          @entity_type = type unless type.nil?
          @entity_type.nil? ? 
            (self.superclass.respond_to?(:entity_type) ?
             self.superclass.entity_type : nil) :
             @entity_type
        end

        # Register a method to be invoked after serverside entit(y|ies)
        # are retrieved to perform additional client side verification
        # of the entity type.
        #
        # @example
        #   class MiningShip
        #     include Trackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #     entity_validation { |e| e.type == :miner }
        #   end
        def entity_validation(&bl)
          @entity_validation ||= []
          @entity_validation << bl unless bl.nil?
          @entity_validation +
            (self.superclass.respond_to?(:entity_validation) ?
             self.superclass.entity_validation : [])
        end

        # Register a method to be invoked after instance of this class
        # is created by local mechanisms.
        #
        # For this reason, when using Trackable, instances of
        # the class including it should only be created through the
        # instantiation methods defined here.
        def entity_init(&bl)
          @entity_init ||= []
          @entity_init << bl unless bl.nil?
          @entity_init +
            (self.superclass.respond_to?(:entity_init) ?
             self.superclass.entity_init : [])
        end

        # Get/set the method used to retrieve serverside entities.
        def get_method(method_name=nil)
          @get_method = method_name unless method_name.nil?
          @get_method.nil? ? 
            (self.superclass.respond_to?(:get_method) ?
             self.superclass.get_method : nil) :
             @get_method
        end

        # Manually get/set the event setup callbacks
        #
        # @see entity_event below
        def event_setup(callbacks=nil)
          @event_setup ||= {}
          @event_setup = callbacks unless callbacks.nil?

          (self.superclass.respond_to?(:event_setup) ?
           self.superclass.event_setup : {}).merge(@event_setup)
        end

        # Define an event on this entity type which clients can register
        # handlers for specific entity instances.
        #
        # @example
        #   class MiningShip
        #     include Trackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #
        #     entity_event :resource_collected =>
        #       { :subscribe    => "manufactured::subscribe_to",
        #         :notification => "manufactured::event_occurred",
        #         :match => proc { |e,*args| args[1] == e.id } }
        #
        # @param [Hash<Symbol,Hash>] events hash of event ids to event options
        # @option events [Callable] :setup method to be invoked w/ entity to begin listening for events
        # @option events [String] :subscribe server method to invoke to being listening for events
        # @option  events [String] :notification local rjr method invoked by server to notify client event occurred.
        # @option  events [Callable] :match optional callback to validate if notification matches local entity
        # @option  events [Callable] :update optional callback to update entity before handling notification
        def entity_event(events = {})
          events.keys.each { |e|
            event_setup = []

            # TODO skip subscription/notification handling
            # if already listening for this entity ?

            if events[e].has_key?(:setup)
              event_setup << events[e][:setup]
            end

            if events[e].has_key?(:subscribe)
              event_setup << lambda { |*args|
                self.node.invoke(events[e][:subscribe], self.entity.id, e)
              }
            end

            if events[e].has_key?(:notification)
              event_setup << lambda { |*args|
                @event_serializer = Mutex.new
                @handled ||= []
                unless @handled.include?(e)
                  notification = events[e][:notification]
                  self.node.handle(notification) { |*args|
                    if events[e][:match].nil? || events[e][:match].call(self, *args)
                      @event_serializer.synchronize {
                        events[e][:update].call(self, *args) if events[e][:update]
                        self.raise_event e, *args
                      }
                    end
                  }
                  @handled << e
                end
              }
            end

            @event_setup ||= {}
            @event_setup[e] = event_setup
          }
        end

        # Return array of all server side entities
        # tracked by this class
        #
        # @example
        #   class Ship
        #     include Trackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #   end
        #
        #   Ship.get_all
        #   # => [<Omega::Client::Ship#...>,<Omega::Client::Ship#...>,...]
        #
        # @return [Array<Trackable>] all entities which server returns
        def get_all
          node.invoke(self.get_method,
                      'of_type', self.entity_type).
               select  { |e| validate_entity(e) }.
               collect { |e| track_entity(e) }
        end

        # Return entity tracked by this class corresponding to id,
        # or nil if not found
        #
        # @example
        #   class Ship
        #     include Trackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #   end
        #
        #   Ship.get('ship1')
        #   # => <Omega::Client::Ship#...>
        #
        # @return [nil,Trackable] entity corresponding to id, nil if not found
        def get(id)
          e = track_entity node.invoke(self.get_method,
                                       'with_id', id)
          return nil unless validate_entity(e)
          e
        end

        # Return array of all server side entities
        # tracked by this class owned by the specified user
        #
        # TODO move this into its own module
        #
        # @example
        #   class Ship
        #     include Trackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #   end
        #
        #   Ship.owned_by('Anubis')
        #   # => [<Omega::Client::Ship#...>,<Omega::Client::Ship#...>,...]
        #
        # @return [Array<Trackable>] entities owned by specified user which server returns
        def owned_by(user_id)
          node.invoke(self.get_method,
                      'of_type', self.entity_type,
                      'owned_by', user_id).
               select  { |e| validate_entity(e) }.
               collect { |e| track_entity(e) }
        end

        private

        # Internal helper to initialize the local class w/ the entity
        # retieved by the server and to invoke init callbacks
        def track_entity(e)
          tracked = self.new
          tracked.entity = e
          init_entity(tracked)
          tracked
        end

        # Internal helper to invoke init callbacks on entity
        def init_entity(e)
          return if self.entity_init.nil?
          self.entity_init.each { |init_method|
            e.instance_exec(e, &init_method)
          }
        end

        # Internal helper to invoke entity validation method on entity
        def validate_entity(e)
          return true if self.entity_validation.nil?
          self.entity_validation.all? { |v| v.call(e) }
        end
      end
    end

    # Include TrackState in a Trackable class to
    # register handlers to be invoked on various custom user defined states
    # of the server side entity.
    #
    # Note is up to the developer to seperate register events and handlers to
    # update the local entity from the server side state
    # @see Trackable above
    #
    # @example
    #   class Ship
    #     include Trackable
    #     include TrackState
    #     entity_type Manufactured::Ship
    #     get_method "manufactured::get_entity"
    #
    #     server_state :cargo_full,
    #       :check => lambda { |e| e.cargo_full?       },
    #       :on    => lambda { |e| e.offload_resources },
    #       :off   => lambda { |e|}
    #
    #     def offload_resources
    #       # ...
    #     end
    #   end
    module TrackState

      # The class methods below will be defined on the
      # class including this module
      #
      # @see ClassMethods
      def self.included(base)
        base.extend(ClassMethods)
      end

      # States the entity currently has
      attr_accessor :states

      # Register handler to be invoked when the entity enters the
      # specified state
      #
      # @param [Symbol] state identifier of the state which to register handler for
      # @param [Callable] bl callback to invoke when entity enters state
      def on_state(state, &bl)
        @on_state_callbacks[state]  ||= []
        @on_state_callbacks[state]  << bl
      end

      # Register handler to be invoked when the entity leaves the
      # specified state
      #
      # @param [Symbol] state identifier of the state which to register handler for
      # @param [Callable] bl callback to invoke when entity leaves state
      def off_state(state, &bl)
        @off_state_callbacks[state] ||= []
        @off_state_callbacks[state] << bl
      end

      #######################################################################
      # these methods are private / used internally

      # This method is invoked by the tracker module when the entity
      # enters the specified state
      #
      # @scope private
      def set_state(state)
        return if @states.include?(state) # TODO add flag to disable this check
        @states << state
        @on_state_callbacks[state].each { |cb|
          instance_exec self, &cb
        } if @on_state_callbacks.has_key?(state)
      end

      # This method is invoked by the tracker module when the entity
      # leaves the specified state
      #
      # @scope private
      def unset_state(state)
        if(@states.include?(state))
          @states.delete(state)
          @off_state_callbacks[state].each { |cb|
            instance_exec self, &cb
          } if @off_state_callbacks.has_key?(state)
        end
      end

      # Methods that are defined on the class including 
      # the TrackState module
      module ClassMethods
        # Define a state for this entity type which clients can register
        # on/off handlers for specific entity instances.
        #
        # This method registers a callback to be invoked on entity
        # initialization, integrating the local entity w/ the TrackState module
        # after which an entity updated event handler is registered to detect
        # changes in state
        #
        # All callbacks registered here are invoked in the context of the entity
        # w/ self as the only param
        #
        # @param [Symbol] state entity state which to define
        # @param [Hash<Symbol,Callable>] args callbacks to use during the state lifecycle
        # @option args [Callable] :check callback to invoke to check if the entity is
        #   in the specified state, should return true/false
        # @option args [Callable] :on callback to invoke when entity enters the specified state
        # @option args [Callable] :off callback to invoke when entity leaves the specified state
        def server_state(state, args = {})
          entity_init { |e|
            @states              ||= []
            @on_state_callbacks  ||= {}
            @off_state_callbacks ||= {}

            if args.has_key?(:on)
              on_state(state, &args[:on])
            end

            if args.has_key?(:off)
              off_state(state, &args[:off])
            end

            @condition_checks ||= {}
            if args.has_key?(:check)
              @condition_checks[state] = args[:check]
            end

            e.handle(:all){
              #return if \@updating_state
              #\@updating_state = true
              @condition_checks.each { |st,check|
                if instance_exec(e, &check)
                  e.set_state st
                else
                  e.unset_state st
                end
              }
              #\@updating_state = false
            }
          }
        end
      end # module ClassMethods
    end # module TrackState

    module TrackEntity
      # The class methods below will be defined on the
      # class including this module
      #
      # @see ClassMethods
      def self.included(base)
        @entities ||= []

        base.extend(ClassMethods)

        # On initialization register entities w/ registry,
        # deleting old entity if it exists
        base.entity_init { |e|
          TrackEntity.track_entity e
        }
      end

      # Instance wrapper around class.entities
      def entities
        self.class.entities
      end

      # Track specified entity
      def self.track_entity(e)
        o = @entities.find { |re| re.id == e.id }
        @entities.delete(o) unless o.nil?
        @entities << e
      end

      # Return all entities in all classes w/ TrackEntity.entities
      def self.entities
        @entities
      end

      # Clear all entities
      def self.clear_entities
        @entities = []
      end

      # Methods that are defined on the class including 
      # the TrackState module
      module ClassMethods
        # Return all entities of the local type
        def entities
          TrackEntity.entities.select { |e| e.kind_of?(self) }
        end

        # Only clear entities on the local type
        def clear_entities
          le = entities
          TrackEntity.entities.reject! { |e| le.include?(e) }
        end

        # Refresh all entities
        def refresh
          entities.each { |e| e.refresh }
        end

        # Return cached entity, else retrieve
        def cached(id)
          e = entities.find { |e| e.id == id }
          return e unless e.nil?
          self.get id
        end
      end
    end

  end # module Client
end # module Omega
