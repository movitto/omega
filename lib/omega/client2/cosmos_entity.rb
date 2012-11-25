#!/usr/bin/ruby
# omega client cosmos entities tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client2/mixins'
require 'cosmos'

module Omega
  module Client
    class Galaxy
      include RemotelyTrackable
      include HasLocation

      entity_type  Cosmos::Galaxy
      get_method   "cosmos::get_entity"
    end

    class SolarSystem
      include RemotelyTrackable
      include HasLocation

      entity_type  Cosmos::SolarSystem
      get_method   "cosmos::get_entity"

      def self.with_fewest(entity_type)
        systems = []
        if(entity_type == "Manufactured::Station")
          systems +=
            Station.owned_by(Node.user.id).map { |s|
              [s.system_name, s.solar_system]
            }
        end

        system_map = Hash.new(0)
        systems.each { |n,s| system_map[n] += 1 }
        fewest = system_map.sort_by { |n,c| c }.last
        return nil if fewest.nil?
        systems.find { |n,s| n == fewest.first }.last
      end
    end
  end
end
