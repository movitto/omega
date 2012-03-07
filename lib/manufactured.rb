# include all manufactured modules
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

lib = File.dirname(__FILE__)
$: << lib + '/manufactured/'

require lib + '/manufactured/ship'
require lib + '/manufactured/station'
require lib + '/manufactured/fleet'
require lib + '/manufactured/commands'
require lib + '/manufactured/callbacks'
require lib + '/manufactured/rjr_adapter'
require lib + '/manufactured/registry'
