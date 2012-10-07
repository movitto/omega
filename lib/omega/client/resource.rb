#!/usr/bin/ruby
# omega client cosmos entities tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'

module Omega
  module Client
    class ResourceSource
      def self.associated_with(entity_name)
        Tracker.invoke_request('cosmos::get_resource_sources', entity_name).collect { |rs|
          e = self.new :resource_source => rs
          e = Tracker["Cosmos::ResourceSource-#{rs.id}"] = e

          e.update(rs)
          e
        }
      end

      def update(rs)
        @rs_lock.synchronize{
          self.quantity = rs.quantity
          self.resource = rs.resource
          self.entity   = rs.entity
        }
        return self
      end

      def -(quantity)
        @rs_lock.synchronize{
          self.quantity -= quantity
        }
        return self
      end

      def initialize(args = {})
        @resource_source = args[:resource_source]
        @rs_lock = Mutex.new {}
      end

      def method_missing(method_id, *args, &bl)
        @resource_source.send method_id, *args, &bl
      end
    end
  end
end
