# Missions Server DSL
#
# Various callbacks and utility methods for use in mission creation.
#
# The DSL methods themselves just return procedures to be registered
# with the various mission callback to be executed at various stages
# in the mission lifecycles (assignment, victory, expiration, etc)
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'missions/dsl/client'
require 'missions/dsl/requirements'
require 'missions/dsl/assignment'
require 'missions/dsl/event'
require 'missions/dsl/event_handler'
require 'missions/dsl/query'
require 'missions/dsl/resolution'
