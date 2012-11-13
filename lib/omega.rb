# include all omega project modules
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# The Omega Simulation Framework
module Omega ; end

require 'rjr'

require 'omega/exceptions'
require 'omega/roles'
require 'omega/names'
require 'omega/resources'
require 'omega/client'
require 'omega/config'

require 'omega/client/base'
require 'omega/client/user'
require 'omega/client/location'
require 'omega/client/cosmos_entity'
require 'omega/client/ship'
require 'omega/client/station'

require 'omega/bot/miner'
require 'omega/bot/corvette'
require 'omega/bot/factory'

require 'omega/colored'
#require 'omega/ncurses'

require 'motel'
require 'cosmos'
require 'manufactured'
require 'users'
