# Omega Trackable Client Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

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
        @entity = node.invoke(self.class.get_method, 'with_id', id)
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

      # Clear all handlers
      def clear_handlers
        @event_handlers = nil
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
            ::RJR::Logger.warn "err in #{id} #{event} handler:"
            ::RJR::Logger.warn "#{([e] + e.backtrace).join("\n")}"
          end

        } if @event_handlers && @event_handlers[event]

        # run :all callbacks
        @event_handlers[:all].each { |eh|
          begin
            eh.call self, *eargs
          rescue Exception, StandardError => e
            ::RJR::Logger.warn "err in #{id} 'all' handler:"
            ::RJR::Logger.warn "#{([e] + e.backtrace).join("\n")}"
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
      end # module ClassMethods
    end # module Trackable
  end # module Client
end # module Omega
