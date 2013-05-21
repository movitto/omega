# include all omega project modules
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# The Omega Simulation Framework
module Omega ; end

require 'rjr'

require 'omega/common'
require 'omega/exceptions'
require 'omega/roles'
require 'omega/names'
require 'omega/resources'

require 'omega/client/node'
require 'omega/client/dsl'
require 'omega/client/mixins'

require 'omega/client/user'
require 'omega/client/cosmos_entity'
require 'omega/client/ship'
require 'omega/client/station'

require 'motel'
require 'cosmos'
require 'manufactured'
require 'users'
require 'missions'
require 'stats'

require 'omega/config'
