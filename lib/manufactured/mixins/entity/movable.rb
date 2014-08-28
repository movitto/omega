# Manufactured Movable Entity Mixin
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'cosmos/resource'
require 'omega/constraints'

module Manufactured
module Entity
  module Movable
    include Omega::ConstrainedAttributes

    def self.included(base)
      base.inherit_constraints self
    end

    # Total distance ship moved
    attr_accessor :distance_moved

    # @!group Movement Properties

    # Distance ship travels during a single movement cycle
    constrained_attr(:movement_speed, :intern => true) { |speeds| speeds[type] || speeds[:default] }

    # Acceleration applied to velocity during each movement cycle
    constrained_attr(:acceleration,   :intern => true) { |accelerations| accelerations[type] || accelerations[:default] }

    # Max angle ship can rotate in a single movmeent cycle
    constrained_attr(:rotation_speed, :intern => true) { |speeds| speeds[type] || speeds[:default] }

    # @!endgroup

    # Initialize movement properties from args
    def movement_state_from_args(args)
      attr_from_args args, :distance_moved => 0
    end

    # Return movement attributes which are updatable
    def updatable_movement_attrs
      @updatable_movement_attrs ||= [:distance_moved]
    end

    def movement_json
      {:distance_moved => @distance_moved}
    end
  end # module Movable
end # module Entity
end # module Manufactured
