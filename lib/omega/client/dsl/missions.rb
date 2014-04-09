# Omega Client DSL Missions Interface
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/events/periodic'

module Omega
  module Client
    module DSL
      # Schedule new periodic event w/ missions subsystem
      #
      # @param [Integer] interval which event should occur
      # @param [Missions::Event] event event which to run at specified interval
      def schedule_event(interval, event)
        evnt =
          Omega::Server::PeriodicEvent.new :id => event.id + '-scheduler',
                                           :interval => interval,
                                           :template_event => event
        RJR::Logger.info "Scheduling event #{evnt}(#{event})"
        notify 'missions::create_event', evnt
        evnt
      end

      # Create a new Missions::Mission
      #
      # @param [String] id id to assign to new mission
      # @param[Hash[ args hash of options to pass directly to mission initializer
      def mission(id, args={})
        mission = Missions::Mission.new(args.merge({:id => id}))
        RJR::Logger.info "Creating mission #{mission}"
        notify 'missions::create_mission', mission
        mission
      end

      def missions_event_handler(event, handler_method, args={})
        dsl_handler = Missions::DSL::Client::EventHandler.send(handler_method,
                                                 args.merge({:event => event}))
        handler = Missions::EventHandlers::DSL.new :event_id => event,
                                                   :persist  => true
        handler.exec dsl_handler
        handler
      end
    end # module DSL
  end # module Client
end # module Omega
