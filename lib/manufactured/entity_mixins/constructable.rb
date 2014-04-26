# Manufactured Constructable Entity Mixin
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/resource'
require 'omega/constraints'

module Manufactured
module Entity
  # This module gets 'extended' on manufactured entity classes
  module Constructable
    include Omega::ConstrainedAttributes

    # Cost to construct a ship of the specified type
    constrained_attr :construction_cost

    # Time (in seconds) to construct a ship of the specified type
    constrained_attr :construction_time
  end # module Constructable
end # module Entity
end # module Manufactured
