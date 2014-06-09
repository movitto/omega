# Omega Client HasCargo Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
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
        entities = node.invoke 'manufactured::transfer_resource',
                                self.id, target.id, resource
        @entity = entities.first
        self.raise_event(:transferred_to,       target, resource)

        # XXX only set target entity / raises target
        # event if client entity passed in
        if target.class.to_s =~ /Omega::Client::.*/
          target.entity = entities.last
          target.raise_event(:transferred_from,  self,   resource)
        end
      end
    end
  end # module Client
end # module Omega
