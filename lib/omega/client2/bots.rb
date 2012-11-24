#!/usr/bin/ruby
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module TrackState
      def self.included(base)
        base.extend(ClassMethods)
      end

      def set_state(state)
        @current_states << state
        @on_state_callbacks[state].each { |cb|
          instance_exec self, &cb
        } if @on_state_callbacks.has_key?(state)
      end

      def unset_state(state)
        if(@current_states.include?(state))
          @current_states.delete(state)
          @off_state_callbacks[state].each { |cb|
            instance_exec self, &cb
          } if @off_state_callbacks.has_key?(state)
        end
      end

      def on_state(state, &bl)
        @on_state_callbacks         ||= {}
        @on_state_callbacks[state]  ||= []
        @on_state_callbacks[state]  << bl
      end

      def off_state(state, &bl)
        @off_state_callbacks        ||= {}
        @off_state_callbacks[state] ||= []
        @off_state_callbacks[state] << bl
      end

      module ClassMethods
        def server_state(state, args = {})
          # TODO flag allowing callbacks to be invoked once per state change
          on_init { |e|
            @current_states   ||= []

            if args.has_key?(:on)
              on_state(state, &args[:on])

            elsif args.has_key?(:off)
              off_state(state, &args[:off])

            end

            @condition_checks ||= {}
            if args.has_key?(:check)
              @condition_checks[state] = args[:check]
            end

            return if @handle_state_updates
            @handle_state_updates = true

            e.handle_event(:updated){
              #return if @updating_state
              #@updating_state = true
              @condition_checks.each { |st,check|
                if instance_exec(e, &check)
                  e.set_state st
                else
                  e.unset_state st
                end
              }
              #@updating_state = false
            }
          }
        end
      end
    end
  end
end
