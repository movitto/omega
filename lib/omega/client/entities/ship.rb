# Omega Client Ship Tracker
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/client/mixins'
require 'manufactured/ship'

module Omega
  module Client
    # Omega client Manufactured::Ship tracker
    class Ship
      include Trackable
      include TrackEvents
      include TrackEntity
      include TrackState
      include HasLocation
      include InSystem
      include HasCargo
      include Dockable
      include DefenseCapabilities
      include CollectsLoot

      entity_type  Manufactured::Ship

      get_method   "manufactured::get_entity"
    end
  end
end
