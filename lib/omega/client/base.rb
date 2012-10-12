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

      def self.subscribe_method
        # return rjr method to invoke to subscribe to entity events
        nil
      end

      def self.notification_method
        # return rjr method server will invoke when notifying
        # client of events
        nil
      end

      def self.entity_type
        # return type of specified entity
        nil
      end

      def entity_id
        # return id of specified entity
        # override if entity uses another field for id
        self.entity.id
      end

      def self.entity_id_attr
        # return name of attribute corresponding to unique identitier of entity
        "id"
      end

      # returns true/false indicating if client entity
      # is valid representation of server entity
      def valid?
        true
      end

      def self.get_all
#puts "GET ALL #{entity_type}"
        Tracker.invoke_request(get_method, 'of_type', entity_type).collect { |entity|
          self.new :entity => entity
        }.select  { |e| e.valid?
        }.collect { |entity|
          # if already loaded, use local copy & get update.
          # *yes* we have to do both assignments here, since tracked
          # entity might already be loaded, see Tracker[]= below
          Tracker[entity_type + '-' + entity.entity_id.to_s] = entity
          e = Tracker[entity_type + '-' + entity.entity_id.to_s]

          # update the entity incase it was just loaded from the client cache
          e.update(entity.entity)

          # load relationships
          e.get_associated
          e
        }
      end

      def self.get(id)
#puts "GET ID #{id}"
        entity = Tracker.invoke_request get_method, "with_#{entity_id_attr}", id
        e = self.new :entity => entity
        # throw error if !e.valid?

        # see comment in get_all
        Tracker[entity_type + '-' + e.entity_id.to_s] = e
        e = Tracker[entity_type + '-' + e.entity_id.to_s]

        e.update(entity)

        # load relationships
        e.get_associated
        e
      end

      def self.owned_by(user_id)
#puts "GET OWNED BY #{entity_type}/#{user_id}"
        Tracker.invoke_request(get_method, 'of_type', entity_type, "owned_by", user_id).collect { |entity|
          self.new :entity => entity
        }.select  { |e| e.valid?
        }.collect { |entity|
          # see comment in get_all
          Tracker[entity_type + '-' + entity.entity_id.to_s] = entity
          e = Tracker[entity_type + '-' + entity.entity_id.to_s]

          e.update(entity.entity)

          # load relationships
          e.get_associated
          e
        }
      end

      def entity
        #Tracker.synchronize {
          @entity
        #}
      end

      # exposed so generic server callbacks can update client
      # side entities through the Tracker registry below
      def entity=(entity)
        Tracker.synchronize {
          @entity = entity
        }
      end

      # update entity from that received from server
      def update(val)
        self.entity = val
      end

      # retrieve associated entities from server
      def get_associated
        return self
      end

      # retrieve tracked entity from server
      def get
#puts "GET #{entity_id}"
        self.entity= Tracker.invoke_request self.class.get_method, "with_#{self.class.entity_id_attr}", entity_id
        return self
      end

      def refresh_every(seconds, &bl)
        callback = block_given? ? bl : nil
        # must run asyncronously so as not block em
        Tracker.em_repeat_async(seconds) {
          get
          callback.call self.entity if callback
        }
      end

      # Provides mechanisms to serialize events called by the server
      # on the client. Due to the rjr dispatcher system multiple events
      # on a single object may be served at a single time so we simply
      # serialize incoming events using a queue and then use a job
      # periodically launched by eventmachine to run the event handlers.
      def self.schedule_event_cycle
        @@event_queue ||= Queue.new

        # TODO variable timer
        Omega::Client::Tracker.em_schedule_async(5){
          while @@event_queue.size > 0 && event = @@event_queue.pop
            # TODO surround w/ rescue block ?
            event[0].call *event[1]
          end
          self.schedule_event_cycle
        }
      end

      # Register event handler for the specified event
      def on_event(event, &bl)
        #if event == '*'
        #  @all_events_callback = bl
        #end

        Tracker.synchronize{
          @@event_handlers ||= {}
          @@event_handlers[self.entity.id] ||= {}
          @@event_handlers[self.entity.id][event] ||= []
          @@event_handlers[self.entity.id][event] << bl

          unless @registered_manufactured_events
            @registered_manufactured_events = true
            RJR::Dispatcher.add_handler(self.class.notification_method) { |*args|
              event  = args[0]
              entity = args[event == 'mining_stopped' ? 2 : 1] 
              Omega::Client::Tracker[Omega::Client::Ship.entity_type + '-' + entity.id].entity= entity
              handlers = Tracker.synchronize { Array.new(@@event_handlers[entity.id][event]) }
              handlers.each { |cb| @@event_queue << [cb, args] }
              nil
            }
          end
        }

        @@event_timer ||= self.class.schedule_event_cycle

        self.entity= Tracker.invoke_request self.class.subscribe_method, self.entity.id, event
      end


      def initialize(args = {})
        self.entity  = args[:entity]
      end

      def method_missing(method_id, *args, &bl)
        self.entity.send method_id, *args, &bl
      end
    end

    class Tracker
      include Singleton

      def initialize(args = {})
        @node = args[:node]
        @node_lock = Mutex.new

        # hash of unique ids to handles to all entities retrieved from the server
        @registry = {}
        @registry_lock = Mutex.new

        # provides way to generate incrementing unique ids
        @id_counter = 500 + rand(100)
        @id_counter_lock = Mutex.new
      end

      def node=(node)
        @node = node
        @node.message_headers['source_node'] = @node.node_id
        @node.listen
        @node
      end

      # Run an operation protected by the registry lock
      def synchronize(&bl)
        @registry_lock.synchronize{
          bl.call
        }
      end

      def []=(key, val)
        @registry_lock.synchronize{
           # will only set value the first time
           @registry[key] ||= val
           @registry[key]
        }
      end

      def [](key)
        @registry_lock.synchronize{
          @registry[key]
        }
      end

      def select(&bl)
        @registry_lock.synchronize{
          @registry.select &bl
        }
      end

      def next_id
        @id_counter_lock.synchronize{
          @id_counter += 1
        }
      end

      def invoke_request(method, *args)
        @node_lock.synchronize {
          @node.invoke_request 'json-rpc://localhost:8181', method, *args
        }
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
