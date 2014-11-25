# Motel Movement Strategies
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/movement_strategies/stopped'
require 'motel/movement_strategies/linear'
require 'motel/movement_strategies/rotate'
require 'motel/movement_strategies/elliptical'
require 'motel/movement_strategies/follow'
require 'motel/movement_strategies/figure8'
require 'motel/movement_strategies/towards'

module Motel
  STRATEGY_CLASSES = {
    :stopped    => MovementStrategies::Stopped,
    :linear     => MovementStrategies::Linear,
    :rotate     => MovementStrategies::Rotate,
    :elliptical => MovementStrategies::Elliptical,
    :follow     => MovementStrategies::Follow,
    :figure8    => MovementStrategies::Figure8,
    :towards    => MovementStrategies::Towards
  }

  def self.valid_strategy_class?(id)
    STRATEGY_CLASSES.keys.any? { |cls| cls.to_s == id.to_s }
  end

  def self.strategy_class_for(id)
    return nil unless valid_strategy_class?(id)
    STRATEGY_CLASSES[id.intern]
  end
end
