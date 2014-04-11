# Omega Client Station Tracker
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/mixins'
require 'omega/client/entities/location'
require 'omega/client/entities/in_system'
require 'omega/client/entities/has_cargo'
require 'manufactured/station'

module Omega
  module Client
    # Omega client Manufactured::Station tracker
    class Station
      include Trackable
      include TrackEvents
      include TrackEntity
      include HasLocation
      include InSystem
      include HasCargo

      entity_type  Manufactured::Station

      get_method   "manufactured::get_entity"
    end
  end # module Client
end # module Omega
