# Omega Trackable Client Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

# TODO split up

require 'omega/client/node'

module Omega
  module Client
    # Include the Trackable module in classes to associate
    # instances of the class w/ server side entities.
    #
    # @example
    #   class Ship
    #     include Trackable
    #
    #     entity_type Manufactured::Ship
    #     get_method "manufactured::get_entity"
    #   end
    #
    #   Ship.get('ship1')
    module Trackable
      # @see ClassMethods
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Entity being tracked.
      attr_accessor :entity

      # Refresh entity
      def refresh
        @entity = node.invoke(self.class.get_method, 'with_id', id)
      end

      # By default proxy all methods to underlying entity
      def method_missing(method_id, *args, &bl)
        self.entity.send(method_id, *args, &bl)
      end

      # Instance wrapper around Trackable.node
      def node
        Trackable.node
      end

      # Centralized node to query / manage trackable entities
      def self.node
        @node ||= Omega::Client::Node.new
      end

      private

      # Methods that are defined on the class including
      # the Trackable module
      module ClassMethods

        # Class wrapper around Trackable.node
        def node
          Trackable.node
        end

        # Define server side entity type to track
        def entity_type(type=nil)
          @entity_type = type unless type.nil?
          @entity_type.nil? ?
            (self.superclass.respond_to?(:entity_type) ?
             self.superclass.entity_type : nil) :
             @entity_type
        end

        # Register a method to be invoked after serverside entit(y|ies)
        # are retrieved to perform additional client side verification
        # of the entity type.
        #
        # @example
        #   class MiningShip
        #     include Trackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #     entity_validation { |e| e.type == :miner }
        #   end
        def entity_validation(&bl)
          @entity_validation ||= []
          @entity_validation << bl unless bl.nil?
          @entity_validation +
            (self.superclass.respond_to?(:entity_validation) ?
             self.superclass.entity_validation : [])
        end

        # Register a method to be invoked after instance of this class
        # is created by local mechanisms.
        #
        # For this reason, when using Trackable, instances of
        # the class including it should only be created through the
        # instantiation methods defined here.
        def entity_init(&bl)
          @entity_init ||= []
          @entity_init << bl unless bl.nil?
          @entity_init +
            (self.superclass.respond_to?(:entity_init) ?
             self.superclass.entity_init : [])
        end

        # Get/set the method used to retrieve serverside entities.
        def get_method(method_name=nil)
          @get_method = method_name unless method_name.nil?
          @get_method.nil? ?
            (self.superclass.respond_to?(:get_method) ?
             self.superclass.get_method : nil) :
             @get_method
        end

        # Return array of all server side entities
        # tracked by this class
        #
        # @example
        #   class Ship
        #     include Trackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #   end
        #
        #   Ship.get_all
        #   # => [<Omega::Client::Ship#...>,<Omega::Client::Ship#...>,...]
        #
        # @return [Array<Trackable>] all entities which server returns
        def get_all
          node.invoke(self.get_method,
                      'of_type', self.entity_type).
               select  { |e| validate_entity(e) }.
               collect { |e| track_entity(e) }
        end

        # Return entity tracked by this class corresponding to id,
        # or nil if not found
        #
        # @example
        #   class Ship
        #     include Trackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #   end
        #
        #   Ship.get('ship1')
        #   # => <Omega::Client::Ship#...>
        #
        # @return [nil,Trackable] entity corresponding to id, nil if not found
        def get(id)
          e = track_entity node.invoke(self.get_method,
                                       'with_id', id)
          return nil unless validate_entity(e)
          e
        end

        # Return array of all server side entities
        # tracked by this class owned by the specified user
        #
        # TODO move this into its own module
        #
        # @example
        #   class Ship
        #     include Trackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #   end
        #
        #   Ship.owned_by('Anubis')
        #   # => [<Omega::Client::Ship#...>,<Omega::Client::Ship#...>,...]
        #
        # @return [Array<Trackable>] entities owned by specified user which server returns
        def owned_by(user_id)
          node.invoke(self.get_method,
                      'of_type', self.entity_type,
                      'owned_by', user_id).
               select  { |e| validate_entity(e) }.
               collect { |e| track_entity(e) }
        end

        private

        # Internal helper to initialize the local class w/ the entity
        # retieved by the server and to invoke init callbacks
        def track_entity(e)
          tracked = self.new
          tracked.entity = e
          init_entity(tracked)
          tracked
        end

        # Internal helper to invoke init callbacks on entity
        def init_entity(e)
          return if self.entity_init.nil?
          self.entity_init.each { |init_method|
            e.instance_exec(e, &init_method)
          }
        end

        # Internal helper to invoke entity validation method on entity
        def validate_entity(e)
          return true if self.entity_validation.nil?
          self.entity_validation.all? { |v| v.call(e) }
        end
      end # module ClassMethods
    end # module Trackable
  end # module Client
end # module Omega
