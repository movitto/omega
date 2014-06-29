# Manufactured MiningCapabilities Entity Mixin
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'cosmos/resource'
require 'omega/constraints'

module Manufactured
module Entity
  module MiningCapabilities
    include Omega::ConstrainedAttributes

    def self.included(base)
      base.inherit_constraints self
    end

    # {Cosmos::Resource} ship is mining, nil if not mining
    attr_accessor :mining

    # @!group Mining Properties

    # Number of mining operations per second ship can perform
    constrained_attr :mining_rate

    # Quatity of resource being mined that can be extracted each time mining operation is performed
    constrained_attr :mining_quantity

    # Max distance ship may be from entity to mine it
    constrained_attr :mining_distance

    # @!endgroup

    # Initialize mining properties from args
    def mining_state_from_args(args)
      attr_from_args args, :mining => nil
    end

    # Return boolean indicating if ship is currently mining
    #
    # @return [true,false] indicating if ship is mining or not
    def mining?
      !@mining.nil?
    end

    # Set ship's mining target
    #
    # @param [Cosmos::Resource] resource resource ship is mining
    def start_mining(resource)
      @mining = resource
    end

    # Clear ship's mining target
    def stop_mining
      @mining = nil
    end

    # Return true / false indicating if ship can mine entity
    #
    # @param [Cosmos::Resource] resource to check if ship can mine
    # @return [true,false] indicating if ship can mine resource source
    def can_mine?(resource, quantity=resource.quantity)
      # TODO eventually filter per specific resource mining capabilities
       type == :mining && !self.docked? && alive? &&
      (location.parent_id == resource.entity.location.parent_id) &&
      (location - resource.entity.location) <= mining_distance &&
      (cargo_quantity + quantity) <= cargo_capacity
    end

    # Return boolean indicating if mining context is valid
    def mining_context_valid?
      (@mining.nil? ||
       (@mining.is_a?(Cosmos::Resource) && can_mine?(@mining)))
    end

    # Return mining attributes which are updatable
    def updatable_mining_attrs
      @updatable_mining_attrs ||= [:mining]
    end

    # Return mining attributes in json format
    def mining_json
      {:mining_distance => mining_distance,
       :mining          => mining}
    end
  end # module MiningCapabilities
end # module Entity
end # module Manufactured
