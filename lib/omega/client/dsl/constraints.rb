# Omega Client DSL Constraints Interface
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/constraints'

module Omega
  module Client
    module DSL
      # Generate the specified constraint
      def constraint(*target)
        Constraints.gen *target
      end

      # Randomly invert constraint value or values
      def rand_invert(value)
        Constraints.rand_invert value
      end

      # Return the default orbital plane
      def orbital_plane
        [0,1,0]
      end

      # Generate new system position from constraint
      def system_position
        rand_invert constraint('system', 'position')
      end

      # Generate a new system location from constraint
      def system_loc
        loc(system_position)
      end
      alias :sys_loc :system_loc

      # Generate a new planet orbit instance from constraints
      def planet_orbit(axis=nil)
        axis ||= orbital_plane
        p = constraint('planet', 'p')
        e = constraint('planet', 'e')
        s = constraint('planet', 'speed')
        orbit(:e => e, :p => p, :speed => s,
              :direction => random_axis(:orthogonal_to => axis))
      end

      # Generate new asteroid position from constraint
      def asteroid_position
        rand_invert constraint('asteroid', 'position')
      end

      # Generate a new asteroid location from constraint
      def asteroid_loc
        loc(asteroid_position)
      end
      alias :ast_loc :asteroid_loc

      # Generate new system entity position from constraint
      def system_entity_position
        rand_invert constraint('system_entity', 'position')
      end

      # Generate new system entity location from constraint
      def system_entity_loc
        loc(system_entity_position)
      end
      alias :entity_loc :system_entity_loc
      alias :jg_loc     :system_entity_loc
      alias :ship_loc   :system_entity_loc
    end # module DSL
  end # module Client
end # module Omega
