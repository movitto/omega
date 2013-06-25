# Top level omega module, pulls in all data-related classes.
# include this to ensure that json from an omega node
# node will always be able to be deserialized
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# Omega Simulation Framework
module Omega ; end

require 'users/user'
require 'users/role'
require 'users/session'

require 'motel/location'

require 'motel/movement_strategies/stopped'
require 'motel/movement_strategies/rotate'
require 'motel/movement_strategies/linear'
require 'motel/movement_strategies/elliptical'
require 'motel/movement_strategies/follow'

require 'motel/callbacks/movement'
require 'motel/callbacks/rotation'
require 'motel/callbacks/proximity'
require 'motel/callbacks/stopped'

require 'cosmos/resource'
require 'cosmos/entities/galaxy'
require 'cosmos/entities/solar_system'
require 'cosmos/entities/star'
require 'cosmos/entities/asteroid'
require 'cosmos/entities/jump_gate'
require 'cosmos/entities/planet'
require 'cosmos/entities/moon'

require 'manufactured/ship'
require 'manufactured/station'
require 'manufactured/loot'

require 'manufactured/commands/attack'
require 'manufactured/commands/construction'
require 'manufactured/commands/mining'
require 'manufactured/commands/shield_refresh'

require 'missions/mission'
require 'missions/events/manufactured'
require 'missions/events/resources'
