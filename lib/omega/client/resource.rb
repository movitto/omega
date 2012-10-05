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
        Tracker.instance.invoke_request('omega-queue', 'cosmos::get_resource_sources', entity_name).each { |rs|
          self.new :resource_source => rs
        }
      end

      def initialize(args = {})
        @resource_source = args[:resource_source]
      end

      def method_missing(method_id, *args, &bl)
        @resource_source.send method_id, *args, &bl
      end
    end
  end
end
