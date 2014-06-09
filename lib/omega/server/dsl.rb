# Omega Server DSL
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/dsl/args'
require 'omega/server/dsl/node'
require 'omega/server/dsl/events'
require 'omega/server/dsl/session'
require 'omega/server/dsl/entities'
require 'omega/server/dsl/subsystem'
require 'omega/server/dsl/attributes'

module Omega
  module Server

    # Omega Server DSL defining many helper methods
    # for server subsystems.
    #
    # DSL gets included in scope of all Omega RJR handlers,
    # see dsl subsections for specific helpers
    module DSL
    end
  end
end
