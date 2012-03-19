# include all omega project modules
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

lib = File.dirname(__FILE__)
$: << lib + '/omega/'

require 'rjr'

require lib + '/omega/exceptions'
require lib + '/omega/roles'
require lib + '/omega/names'
require lib + '/omega/client'

require lib + '/motel'
require lib + '/cosmos'
require lib + '/manufactured'
require lib + '/users'
