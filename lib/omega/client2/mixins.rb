# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/station'

module Omega
  module Client
    module RemotelyTrackable
      def self.included(base)
        base.extend(ClassMethods)
      end

      def method_missing(method_id, *args, &bl)
        self.entity.send(method_id, *args, &bl)
      end

      def to_s
        self.entity.to_s
      end

      def entity
        Node.get(@entity_id)
      end

      def entity_id=(val)
        @entity_id = val
      end

      def get
        Node.invoke_request self.class.get_method, "with_id", @entity_id
        self
      end

      def handle_event(event, *setup_args, &bl)
        event_setup = self.class.instance_variable_get("@event_setup_#{event}".intern)
        event_setup.each { |cb| instance_exec(*setup_args, &cb) } unless event_setup.nil?
        #self.class.instance_variable_set("@event_setup_#{event}".intern, nil)
        Node.add_event_handler self.id, event, &bl
      end

      def refresh(&bl)
        Node.refresh(self.entity, &bl)
      end

      module ClassMethods
        def entity_type(type=nil)
          return @entity_type if type.nil?
          @entity_type = type
        end

        def entity_validation(&bl)
          # TODO allow registration of multiple methods
          @entity_validation = bl
        end

        def on_init(&bl)
          # TODO allow registration of multiple methods
          @entity_init = bl
        end

        def get_method(method_name=nil)
          return @get_method if method_name.nil?
          @get_method = method_name
        end

        def server_event(events = {})
          events.keys.each { |e|
            event_setup = []

            if events[e].has_key?(:setup)
              event_setup << events[e][:setup]
            end

            if events[e].has_key?(:subscribe)
              event_setup << lambda { |*args| Node.invoke_request(events[e][:subscribe], self.entity.id, e) }
            end

            if events[e].has_key?(:notification) && !Node.has_method_handler_for?(events[e][:notification])
              event_setup << lambda { |*args|
                Node.add_method_handler(events[e][:notification])
                Node.add_event_handler(@entity_id, events[e][:notification]) { |*args|
                  Node.raise_event(e, *args)
                }
              }
            end

            self.instance_variable_set("@event_setup_#{e}".intern, event_setup)
          }
        end

        def get_all
          Node.invoke_request(@get_method, 'of_type', @entity_type).
               select  { |e| validate_entity(e) }.
               collect { |e| track_entity(e) }
        end

        def get(id)
          e = track_entity Node.invoke_request(@get_method, 'with_id', id)
          return nil unless validate_entity(e)
          e
        end

        # TODO move into its own module
        def owned_by(user_id)
          Node.invoke_request(@get_method, 'of_type', @entity_type, 'owned_by', user_id).
               select  { |e| validate_entity(e) }.
               collect { |e| track_entity(e) }
        end

        private
        def track_entity(e)
          tracked = self.new
          tracked.entity_id = e.id
          init_entity(tracked)
          tracked
        end

        def init_entity(e)
          return if @entity_init.nil?
          @entity_init.call(e)
        end

        def validate_entity(e)
          return true if @entity_validation.nil?
          @entity_validation.call(e)
        end


      end
    end

    module HasLocation
      def self.included(base)
        base.extend(ClassMethods)
        base.server_event :movement =>
          { :setup => lambda { |distance|
              Node.invoke_request("motel::track_movement",
                                  self.location.id, distance)
            },
            :notification => "motel::on_movement"
          }
      end

      def location
        Node.get(self.entity.location.id)
      end

      module ClassMethods
      end
    end

    module InSystem
      def self.included(base)
        base.extend(ClassMethods)
        base.server_event :stopped       => {},
                          :jumped        => {}
      end

      def solar_system
        Node.get(self.entity.system_name)
      end

      def closest(type, args = {})
        entities = []
        if(type == :station)
          user_owned = args[:user_owned] ? lambda { |eid, e| e.user_id == Node.user.id } :
                                           lambda { |eid, e| true }
          entities = 
            Node.select { |eid,e| e.is_a?(Manufactured::Station) &&
                                  e.location.parent_id == self.location.parent_id }.
                 select(user_owned).
                 sort    { |a,b| (self.location - a.location) <=>
                                 (self.location - b.location) }

        elsif(type == :resource)
          entities = 
            self.solar_system.asteroids.select { |ast|
              ast.resource_sources.find { |rs| rs.quantity > 0 }
            }.flatten.sort { |a,b|
              (self.location - a.location) <=> (self.location - b.location)
            }
        end

        entities
      end

      def move_to(args, &cb)
        # TODO ignore move if we're @ destination
        loc = args[:location]
        if args.has_key?(:destination)
          if args[:destination] == :closest_station
            loc = closest(:station).location
          else
            loc = args[:destination].location
          end
        end

        nloc = Motel::Location.new(:parent_id => self.location.parent_id,
                                   :x => loc.x, :y => loc.y, :z => loc.z)
        handle_event :movement, (self.location - nloc), &cb unless cb.nil?
        Node.invoke_request 'manufactured::move_entity', self.id, nloc
      end

      def stop_moving
        Node.invoke_request 'manufactured::stop_entity', self.id
      end

      def jump_to(system)
        if system.is_a?(String)
          ssystem = Node.get(system)
          ssystem = Node.invoke_request('cosmos::get_entity', 'with_name', system) if ssystem.nil?
          system  = ssystem
        end

        loc    = Motel::Location.new
        loc.update self.location
        loc.parent_id = system.location.id
        Node.invoke_request 'manufactured::move_entity', self.entity.id, loc
        Node.raise_event(:jumped, self)
      end

      module ClassMethods
      end
    end

    module InteractsWithEnvironment
      def self.included(base)
        base.extend(ClassMethods)
      end

      def mine(resource_source)
        # TODO catch start_mining errors
        Node.invoke_request 'manufactured::start_mining',
                   self.id, resource_source.entity.name,
                            resource_source.resource.id
      end

      def attack(target)
        Node.invoke_request 'manufactured::attack_entity', self.id, target.id
      end

      #def dock(station)
      #end

      #def undock
      #end

      def transfer(quantity, args = {})
        resource_id = args[:of]
        target      = args[:to]

        Node.invoke_request 'manufactured::transfer_resource',
                     self.id, target.id, resource_id, quantity
        Node.raise_event(:transferred, self,   target, resource_id, quantity)
        Node.raise_event(:received,    target, self,   resource_id, quantity)
      end

      def construct(entity_type, args={})
        Node.invoke_request 'manufactured::construct_entity',
               self.entity.id, entity_type, *(args.to_a.flatten)
        Node.raise_event(:constructed, self.entity, constructed)
      end

      module ClassMethods
      end
    end

  end
end
