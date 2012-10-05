#!/usr/bin/ruby
# omega client base object, provides a safe way to monitor server entities
#   and subscribe to events / changes of state
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'singleton'

module Omega
  module Client
    class Entity
      def self.get_method
        # return rjr method to invoke to get entity or entities of specified type
        nil
      end

      def self.entity_type
        # return type of specified entity
        nil
      end

      def entity_id
        # return id of specified entity
        # override if entity uses another field for id
        @entity.id
      end

      def self.entity_id_attr
        # return name of attribute corresponding to unique identitier of entity
        "id"
      end

      def self.get_all
        Tracker.instance.invoke_request('omega-queue', get_method, 'of_type', entity_type).collect { |entity|
          self.new :entity => entity
        }
      end

      def self.get(id)
        entity = Tracker.instance.invoke_request 'omega-queue', get_method, "with_#{entity_id_attr}", id
        self.new :entity => entity
      end

      def self.owned_by(user_id)
        Tracker.instance.invoke_request('omega-queue', get_method, 'of_type', entity_type, "owned_by", user_id).collect { |entity|
          self.new :entity => entity
        }
      end

      # exposed so generic server callbacks can update client
      # side entities through the Tracker registry below
      def entity=(entity)
        @entity_lock.synchronize {
          @entity = entity
          Tracker.instance[self.class.entity_type + '-' + entity_id.to_s] = self
        }
      end

      def get
        @entity = Tracker.instance.invoke_request 'omega-queue', self.class.get_method, "with_#{self.class.entity_id_attr}", entity_id
        Tracker.instance[self.class.entity_type + '-' + entity_id.to_s] = self
      end

      def sync
        @entity_lock.synchronize{
          get
        }
      end

      def refresh_every(seconds, &bl)
        callback = block_given? ? bl : nil
        # must run asyncronously so as not block em
        Tracker.em_schedule_async(seconds) {
          sync
          callback.call @entity if callback
        }
      end

      def initialize(args = {})
        @entity = args[:entity]
        @entity_lock = Mutex.new

        # FIXME will retrieve entity twice in case of get_all and get(id)
        get
      end

      def method_missing(method_id, *args, &bl)
        @entity.send method_id, *args, &bl
      end
    end

    class Tracker
      include Singleton

      def initialize(args = {})
        @node = args[:node]
        @node_lock = Mutex.new

        # hash of unique ids to handles to all entities retrieved from the server
        @registry = {}
      end

      def node=(node)
        @node = node
        @node.message_headers['source_node'] = @node.node_id
        @node.listen
        @node
      end

      def []=(key, val)
        @registry[key] = val
      end

      def [](key)
        @registry[key]
      end

      def method_missing(method_id, *args, &bl)
        @node_lock.synchronize { 
          @node.send method_id, *args, &bl
        }
      end

      def self.method_missing(method_id, *args, &bl)
        Tracker.instance.send method_id, *args, &bl
      end

    end
  end
end
