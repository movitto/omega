# Omega TrackState Client Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
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

            # only need to register state check
            # event handler once as it will check all states
            } unless @checking_state
            @checking_state = true
          }
        end
      end # module ClassMethods
    end # module TrackState
  end # module Client
end # module Omega
