# Manufactured Combatent Entity Mixin
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'cosmos/resource'
require 'omega/constraints'

module Manufactured
module Entity
  module Combatent
    include Omega::ConstrainedAttributes

    def self.included(base)
      base.extend(ClassMethods)
      base.inherit_constraints self
    end

    # {Manufactured::Ship} ship being attacked, nil if not attacking
    foreign_reference :attacking

    # @!group Attack/Defense Properties

    # General weapon category, modifies other attack attributes
    constrained_attr(:weapons_class, :intern => true,
                     :constraint => :weapons_classes) { |classes|
                       classes.has_key?(type) ? classes[type].intern : nil
                     }

    # Max distance ship may be for a target to attack it
    constrained_attr(:attack_distance, :intern => true,
                     :constraint => :attack_distances) { |distances|
                       distances[weapons_class] || distances[:default]
                     }

    # Number of attacks per second ship can launch
    constrained_attr(:attack_rate, :intern => true,
                     :constraint => :attack_rates) { |rates|
                       rates[weapons_class] || rates[:default]
                     }

    # Damage ship deals per hit
    constrained_attr(:damage_dealt, :intern => true) { |damage|
                       damage[weapons_class] || damage[:default]
                     }

    # Max hp the ship can have
    constrained_attr :max_hp

    # Hit points the ship has
    constrained_attr :hp, :constraint => :max_hp,
                          :qualifier  => "<=",
                          :writable   => true

    # Max shield level of the ship
    constrained_attr :max_shield_level

    # Current shield level of the ship
    constrained_attr :shield_level, :constraint => :max_shield_level,
                                    :qualifier  => "<=",
                                    :writable   => true

    # Shield refresh rate in units per second
    constrained_attr :shield_refresh_rate

    # Ship which destroyed this one (or its id) if applicable
    attr_accessor :destroyed_by

    # @!endgroup

    # Initialize combat properties from args
    def combat_state_from_args(args)
      attr_from_args args, :attacking    => nil,
                           :attacking_id => @attacking_id,
                           :shield_level =>  nil,
                           :hp           =>  nil
    end

    # Return true / false indicating if the ship's hp > 0
    def alive?
      @hp > 0
    end

    # Return boolean indicating if ship is currently attacking
    #
    # @return [true,false] indicating if ship is attacking or not
    def attacking?
      !self.attacking_id.nil?
    end

    # Set ship's attack target
    #
    # @param [Manufactured::Ship] defender ship being attacked
    def start_attacking(defender)
      self.attacking = defender
      self.attacking.id = defender.id
    end

    # Clear ship's attacking target
    def stop_attacking
      self.attacking_id = nil
      self.attacking = nil
    end

    # Return true / false indicating if ship can attack entity
    #
    # @param [Manufactured::Entity] entity entity to check if ship can attack
    # @return [true,false] indicating if ship can attack entity
    def can_attack?(entity)
      self.class.attack_types.include?(type) && !self.docked? &&
      (location.parent_id == entity.location.parent_id) &&
      (location - entity.location) <= attack_distance  &&
      alive? && entity.alive?
    end

    # Return boolean indicating if combat context is valid
    def combat_context_valid?
     shield_level <= max_shield_level &&
     (attacking.nil? || (attacking.is_a?(Manufactured::Ship) &&
      can_attack?(attacking) && attacking_id == attacking.id))
    end

    # Return combat attributes which are updatable
    def updatable_combat_attrs
      @updatable_combat_attrs ||=
        [:hp, :shield_level, :attacking, :attacking_id]
    end

    # Return combat ship attributes in json format
    def combat_json
      {:hp               => hp,
       :shield_level     => shield_level,
       :max_hp           => max_hp,
       :max_shield_level => max_shield_level,
       :attack_distance  => attack_distance,
       :attacking_id     => attacking_id}
    end

    module ClassMethods
      def attack_types
        @attack_types ||= get_constraint 'attack_types', :intern => true
      end

      def weapons_classes
        @weapons_classes ||= get_constraint 'weapons_classes', :intern => true
      end

      def attack_distances
        @attack_distances ||= get_constraint 'attack_distances', :intern => true
      end

      def attack_rates
        @attack_rates ||= get_constraint 'attack_rates', :intern => true
      end

      def damage_dealt
        @damage_dealt ||= get_constraint 'damage_dealt', :intern => true
      end
    end
  end # module Combatent
end # module Entity
end # module Manufactured
