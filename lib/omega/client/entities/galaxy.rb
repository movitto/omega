# Omega Client Galaxy Tracker
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/client/mixins'
require 'cosmos/entities/galaxy'

module Omega
  module Client
    # Omega client Cosmos::Entities::Galaxy tracker
    class Galaxy
      include Trackable

      entity_type  Cosmos::Entities::Galaxy
      get_method   "cosmos::get_entity"
    end # class Galaxy
  end # module Client
end # module Omega
