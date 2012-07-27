# include all motel modules
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/exceptions'
require 'motel/callbacks'
require 'motel/runner'
require 'motel/remote_location_manager'
require 'motel/rjr_adapter'

require 'motel/location'
require 'motel/movement_strategy'

require 'motel/movement_strategies/stopped'
require 'motel/movement_strategies/linear'
require 'motel/movement_strategies/elliptical'
require 'motel/movement_strategies/follow'
