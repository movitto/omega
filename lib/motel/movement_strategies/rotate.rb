# The Rotation MovementStrategy
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'motel/movement_strategy'
require 'motel/mixins/movement_strategy/rotatable'

module Motel
module MovementStrategies
# Rotates a location around its own access at a specified speed.
class Rotate < MovementStrategy
  include Rotatable

  def initialize(args = {})
    init_rotation(args)
    super(args)
  end

  # Return boolean indicating if this movement strategy is valid
  def valid?
    valid_rotation?
  end

  # Return true if we should change ms due to rotation
  def change?(loc)
    change_due_to_rotation?(loc)
  end

  # Implementation of {Motel::MovementStrategy#move}
  def move(loc, elapsed_seconds)
    unless valid?
      ::RJR::Logger.warn "rotate movement strategy (#{rot_to_s}) not valid, "\
                         "not proceeding with move"
      return
    end

    ::RJR::Logger.debug "moving location #{loc.id} "\
                        "via rotate movement strategy #{rot_to_s}"

    rotate(loc, elapsed_seconds)
  end

  # Convert movement strategy to json representation and return it
  def to_json(*a)
    { 'json_class' => self.class.name,
      'data'       => { :step_delay => step_delay}.merge(rotation_json)
    }.to_json(*a)
  end

  # Convert movement strategy to human readable string and return it
  def to_s
    "rotate-(#{rot_to_s})"
  end

end # class Rotate
end # module MovementStrategies
end # module Motel
