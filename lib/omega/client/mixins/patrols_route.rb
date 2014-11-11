# Omega Client PatrolsRoute Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module PatrolsRoute
      # visited systems
      attr_accessor :visited

      # Calculate an inter-system route to patrol and move through it.
      def patrol_route
        return unless alive?

        @visited  ||= []

        # add local system to visited list
        @visited << solar_system unless @visited.include?(solar_system)

        # grab jump gate of a neighboring system we haven't visited yet
        jg = solar_system.jump_gates.find { |jg|
               !@visited.collect { |v| v.id }.include?(jg.endpoint_id)
             }

        # if no items in to_visit clear lists
        if jg.nil?
          # if jg can't be found on two subsequent runs,
          # error out / stop bot
          if @patrol_err
            raise_event(:patrol_err)
            return
          end
          @patrol_err = true

          @visited  = []
          patrol_route

        else
          @patrol_err = false
          raise_event(:selected_system, jg.endpoint_id, jg)
          if jg.location - location < jg.trigger_distance
            jump_to(jg.endpoint)
            patrol_route

          else
            dst = jg.trigger_distance / 4
            nl  = jg.location + [dst,dst,dst]
            move_to(:location => nl) {
              jump_to(jg.endpoint)
              patrol_route
            }
          end
        end
      end
    end # module PatrolsRoute
  end # module Client
end # module Omega
