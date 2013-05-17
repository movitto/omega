# include all missions modules
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# Missions Subsystem - provides mechanisms to define and track
# story missions and events
module Missions ; end

require 'missions/common'
require 'missions/mission'
require 'missions/event'
require 'missions/registry'
require 'missions/rjr_adapter'

require 'missions/events/manufactured'
require 'missions/events/resources'
require 'missions/events/periodic'

require 'missions/callbacks'
