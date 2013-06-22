#!/usr/bin/ruby
# omega client cosmos entities tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/mixins'
require 'cosmos/entities/galaxy'
require 'cosmos/entities/solar_system'

module Omega
  module Client
    # Omega client Cosmos::Entities::Galaxy tracker
    class Galaxy
      include Trackable

      entity_type  Cosmos::Entities::Galaxy
      get_method   "cosmos::get_entity"
    end

    # Omega client Cosmos::Entities::SolarSystem tracker
    class SolarSystem
      include Trackable

      entity_type  Cosmos::Entities::SolarSystem
      get_method   "cosmos::get_entity"

      # Conveniency utility to return the system containing
      # the fewest entities of the specified type
      #
      # This will issue a server side request to retrieve
      # entities (and systems they are in via the Client::Node
      # automatically).
      #
      # *note* this will only consider systems w/ entities, systems
      # w/ none of the specified entity will not be returned
      #
      # @param [Hash] args used to filter system retrieved
      # @return [Cosmos::Entities::SolarSystem,nil] system with the fewest entities
      #   or nil if none found
      def self.with_fewest(args={})
        systems = []
        if(args[:type] == "Manufactured::Station")
          systems +=
            Omega::Client::Station.owned_by(args[:owned_by]).map { |s|
              [s.system_id, s.solar_system]
            }
        end

        system_map = Hash.new(0)
        systems.each { |n,s| system_map[n] += 1 }
        fewest = system_map.sort_by { |n,c| c }.first
        return nil if fewest.nil?
        fewest = fewest.first
        systems.find { |s| s.first == fewest }.last
      end

      # Conveniency utility to return the closest neighbor system with
      # entities of the specified type
      #
      # This will issue a server side request to retrieve
      # entities and systems
      #
      # @param [Hash] args used to filter systems retrieved
      # @return [Cosmos::Entities::SolarSystem,nil] closest system with no entities
      #   or nil
      def closest_neighbor_with_no(args={})
        entities = []
        entities = Omega::Client::Station.owned_by(args[:owned_by]) if(args[:type] == "Manufactured::Station")

        systems = [self]
        systems.each { |sys|
          # TODO sort jumpgates by distance from sys to endpoint
          sys.jump_gates.each { |jg|
            endpoint = Omega::Client::SolarSystem.get(jg.endpoint_id)
            if entities.find { |e| e.system_id == jg.endpoint_id }.nil?
              return endpoint
            elsif !systems.include?(jg.endpoint)
              systems << endpoint
            end
          }
        }

        return nil
      end
    end

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
        SolarSystem.get(self.entity.parent_id)
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
        system =
          node.invoke('cosmos::get_entity',
                      'with_id', system) if system.is_a?(String)

        loc    = Motel::Location.new
        loc.update self.location
        loc.parent_id = system.location.id
        RJR::Logger.info "Jumping #{self.entity.id} to #{system}"
        node.invoke 'manufactured::move_entity', self.entity.id, loc
        self.raise_event(:jumped, self)
      end
    end

    # Include the HasCargo module in classes to define
    # helper methods regarding cargo manipulation
    #
    # TODO prolly should go else where
    #
    # @example
    #   class MiningShip
    #     include Trackable
    #     include HasCargo
    #     include InSystem
    #     include InteractsWithEnvironment
    #     entity_type Manufactured::Ship
    #     get_method "manufactured::get_entity"
    #     entity_validation { |e| e.type == :miner }
    #   end
    #
    #   s = MiningShip.get('ship1')
    #   s.transfer_all_to Ship.get('other_ship')
    module HasCargo
      # Transfer all resource sources to target.
      #
      # @param [Manufactured::Ship,Manufactured::Station] target entity to transfer resources to
      def transfer_all_to(target)
        self.resources.each { |rs|
          self.transfer rs, target
        }
      end

      # Transfer specified resource to target.
      #
      # All server side transfer restrictions apply, this method does
      # not do any checks b4 invoking transfer_resource so if server raises
      # a related error, it will be reraised here
      #
      # @param [Resource] resource resource to transfer
      # @option [Entity] target entity to transfer resource to
      def transfer(resource, target)
        RJR::Logger.info "Transferring #{resource} to #{target}"
        node.invoke 'manufactured::transfer_resource',
                     self.id, target.id, resource
        self.raise_event(:transferred, self,   target, resource)
        #self.raise_event(:received,    target, self,   resource)
      end
    end

  end
end
