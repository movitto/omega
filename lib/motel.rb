# include all motel modules
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# Motel - Movable Objects Encompassing Locations - Provides mechanisms
# to define and manipulate heirarchies of locations in a 3d caresian space

require 'motel/exceptions'
require 'motel/callbacks'
require 'motel/runner'
require 'motel/remote_location_manager'
require 'motel/rjr_adapter'

require 'motel/location'
require 'motel/movement_strategy'

require 'motel/movement_strategies/stopped'
require 'motel/movement_strategies/rotate'
require 'motel/movement_strategies/linear'
require 'motel/movement_strategies/elliptical'
require 'motel/movement_strategies/follow'
