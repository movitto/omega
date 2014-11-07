# Omega Client OffenseCapabilities Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module OffenseCapabilities
      def self.included(base)
        base.entity_event \
          :attacked =>
            { :subscribe    => "manufactured::subscribe_to",
              :notification => "manufactured::event_occurred",
              :match => proc { |entity, *a|
                a[0] == 'attacked' && a[1].id == entity.id
              }},

          :attacked_stop =>
            { :subscribe    => "manufactured::subscribe_to",
              :notification => "manufactured::event_occurred",
              :match => proc { |entity, *a|
                a[0] == 'attacked_stop' && a[1].id == entity.id
              }}
      end

      # Attack the specified target
      #
      # All server side attack restrictions apply, this method does
      # not do any checks b4 invoking attack_entity so if server raises
      # a related error, it will be reraised here
      #
      # @param [Manufactured::Ship,Manufactured::Station] target entity to attack
      def attack(target)
        RJR::Logger.info "Starting to attack #{target.id} with #{id}"
        node.invoke 'manufactured::attack_entity', id, target.id
      end
    end # module OffenseCapabilities
  end # module Client
end # module Omega
