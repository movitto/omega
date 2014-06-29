# Motel HasMovementStrategy Mixin.
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/movement_strategy'

module Motel

# Mixed into Location, provides movement strategy accessors and helpers
module HasMovementStrategy
  # [Motel::MovementStrategy] Movement strategy through which to move location
  attr_accessor :movement_strategy
  alias :ms :movement_strategy
  alias :ms= :movement_strategy=

  # Next movement strategy, optionally used to register
  # a movement strategy which to set next
  attr_accessor :next_movement_strategy

  # Return movement strategy attrs
  def movement_strategy_attrs
    [:movement_strategy, :next_movement_strategy]
  end

  # Return movement strategy attributes by scope
  def scoped_movement_strategy_attrs(scope)
    case(scope)
    when :create then
      [:movement_strategy]
    end
  end

  # Initialize default movement strategy / movement strategy from arguments
  def movement_strategy_from_args(args)
    # default to the stopped movement strategy
    attr_from_args args,
      :movement_strategy      => MovementStrategies::Stopped.instance,
      :next_movement_strategy => nil
  end

  # true/false indicating if movement strategy is stopped
  def stopped?
    self.movement_strategy == Motel::MovementStrategies::Stopped.instance
  end

  # Return bool indicating if movement strategy is valid
  def movement_strategy_valid?
    @movement_strategy.kind_of?(MovementStrategy) && @movement_strategy.valid?
  end

  # Return movement strategy in json format
  def movement_strategy_json
    {:movement_strategy => movement_strategy,
     :next_movement_strategy => next_movement_strategy}
  end

  # True/false indicating if location should be moved.
  def should_move?
    last_moved_at.nil? || time_since_movement > movement_strategy.step_delay
  end

  # Remaining time we have until next movement
  def time_until_movement
    movement_strategy.step_delay - (time_since_movement || 0)
  end

  # Return bool indicating if movement strategy is equal to other's
  def movement_strategy_eql?(other)
    movement_strategy == other.movement_strategy
  end
end # module HasMovementStrategy
end # module Motel
