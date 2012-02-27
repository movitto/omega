# include all cosmos modules
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

lib = File.dirname(__FILE__)
$: << lib + '/cosmos/'

require lib + '/cosmos/galaxy'
require lib + '/cosmos/solar_system'
require lib + '/cosmos/star'
require lib + '/cosmos/planet'
require lib + '/cosmos/moon'
require lib + '/cosmos/jump_gate'
require lib + '/cosmos/rjr_adapter'
require lib + '/cosmos/registry'
