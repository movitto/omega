# Omega Client InSystem Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    # Include the InSystem module in classes to define
    # various utility methods to perform system-specific
    # movement operations
    #
    # @example
    #   class Ship
    #     include Trackable
    #     include HasLocation
    #     include InSystem
    #     entity_type Manufactured::Ship
    #     get_method "manufactured::get_entity"
    #   end
    #
    #   # issue a server side request to move ship
    #   s = Ship.get('ship1')
    #   s.move_to(:location => Motel::Location.new(:x => 100, :y => 200, :z => -150))
    module InSystem
      # Always return latest system
      #
      # @return [Cosmos::Entities::SolarSystem]
      def solar_system
        # XXX don't like having require here,
        # but avoids a load time circular dep
        require 'omega/client/entities/solar_system'
        SolarSystem.cached(self.entity.parent_id)
      end

      # Return the closest entity of the specified type.
      #
      # *note* this will only search entities in the local registry,
      # it does not currently call out to the server to retrieve entities
      #
      # @param [Symbol] type of entity to retrieve (currently accepts :station, :resource)
      # @param [Hash] args hash of optional arguments to use in lookup
      # @option args [true,false] :user_owned boolean indicating if we should only return
      #   entities owned by the logged in user
      # @return [Array<Object>] entities in local registry matching criteria
      def closest(type, args = {})
        entities = []
        if(type == :station)
          #user_owned = args[:user_owned] ? lambda { |e| e.user_id == Node.user.id } :
          #                                 lambda { |e| true }
          entities =
            Omega::Client::Station.entities.select { |e|
              e.location.parent_id == self.location.parent_id
            }.#select(&user_owned).
              sort    { |a,b| (self.location - a.location) <=>
                              (self.location - b.location) }

        elsif(type == :resource)
          entities =
            self.solar_system.asteroids.select { |ast|
              ast.resources.find { |rs| rs.quantity > 0 }
            }.flatten.sort { |a,b|
              (self.location - a.location) <=> (self.location - b.location)
            }
        end

        entities
      end

      # Issue server side call to move entity to specified destination,
      # optionally registering callback to be invoked when it gets there.
      #
      # *note* this will register a movement event callback in addition to
      # any ones previously added / added later
      #
      # @param [Hash<Symbol,Object>] args arguments to used to determine destiantion
      # @option args [Motel::Location] :location exact location to move to
      # @option args [:closest_station,Object] :destination destination to move to
      #   through which location will be inferred / extracted
      # @param [Callable] cb optional callback to be invoked when entity arrives at location
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
        clear_handlers_for :movement
        handle :movement, (self.location - nloc), &cb unless cb.nil?
        RJR::Logger.info "Moving #{self.id} to #{nloc}"
        node.invoke 'manufactured::move_entity', self.id, nloc
      end

      # Invoke a server side request to stop movement
      def stop_moving
        RJR::Logger.info "Stopping movement of #{self.id}"
        node.invoke 'manufactured::stop_entity', self.id
      end

      # Invoke a server side request to jump to the specified system
      #
      # Raises the :jumped event on entity
      #
      # @param [Cosmos::Entities::SolarSystem,Omega::Client::SolarSystem,String] system system or name of system which to jump to
      def jump_to(system)
        # TODO should we refresh system anyways even if its a SolarSystem instance?
        system =
          node.invoke('cosmos::get_entity',
                      'with_id', system) if system.is_a?(String)

        loc    = Motel::Location.new
        loc.update self.location
        loc.parent_id = system.location.id
        RJR::Logger.info "Jumping #{self.entity.id} to #{system}"
        @entity = node.invoke 'manufactured::move_entity', self.entity.id, loc
        self.raise_event(:jumped)
      end
    end # module InSystem
  end # module Client
end # module Omega
