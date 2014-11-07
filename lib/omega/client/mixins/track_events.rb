# Omega TrackEvents Client Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module TrackEvents
      # @see ClassMethods
      def self.included(base)
        base.extend(ClassMethods)
      end

      attr_accessor :event_handlers

      # Register handler for the specified event
      #
      # @param [Symbol] event event to handle
      # @param [Array<Object>] args initialization parameters
      # @param [Callable] handler callback to invoke on event
      def handle(event, *args, &handler)
        @setup_events ||= []
        unless @setup_events.include?(event)
          @setup_events << event
          esetup = self.class.event_setup[event]

          esetup.each { |cb|
            self.instance_exec(*args, &cb)
          } unless esetup.nil?
        end

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
        @setup_events   = []
      end

      # Clear handlers for the specified event
      def clear_handlers_for(event)
        @event_handlers[event] = [] if @event_handlers
        @setup_events.delete(event) if @setup_events
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

      # TrackEvents class methods
      module ClassMethods
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
        #     include TrackEvents
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
              event_setup << subscription_setup(e, events[e])
            end

            if events[e].has_key?(:notification)
              event_setup << notification_setup(e, events[e])
            end

            @event_setup  ||= {}
            @event_setup[e] = event_setup
          }
        end

        private

        # Helper to return subscription setup method
        def subscription_setup(event, opts)
          lambda { |*args|
            subscribe_method = opts[:subscribe]
            node.invoke(subscribe_method, entity.id, event)
          }
        end

        # Helper to return notification setup method
        def notification_setup(event, opts)
          lambda { |*args|
            @handled ||= []
            unless @handled.include?(event)
              handle_notification(event, opts)
              @handled << event
            end
          }
        end
      end # module ClassMethods

      def handle_notification(event, opts)
        notification = opts[:notification]
        node.handle(notification) { |*args|
          matcher = opts[:match]
          should_handle = matcher.nil? || matcher.call(self, *args)
          on_notification(event, args, opts) if should_handle
        }
      end

      def on_notification(event, event_args, opts)
        @event_serializer ||= Mutex.new
        @event_serializer.synchronize {
          updater = opts[:update]
          updater.call(self, *event_args) if updater
          raise_event event, *event_args
        }
      end
    end # module TrackEvents
  end # module Client
end # module Omega
