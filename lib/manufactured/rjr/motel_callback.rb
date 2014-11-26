# Manufactured Subsystem Motel RJR Callbacks
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'

module Manufactured::RJR
  # Registered w/ local dispatcher & invoked on motel callbacks
  motel_callback = proc { |loc|
    raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)

    # retrieve registry entity / location
    entity = registry.entity { |e| e.is_a?(Ship) && e.location.id == loc.id }
    unless entity.nil?
      oloc = entity.location

      # update user attributes
      if(oloc.movement_strategy.is_a?(Motel::MovementStrategies::Linear))
        node.invoke('users::update_attribute', entity.user_id,
                    Users::Attributes::DistanceTravelled.id,
                    entity.distance_moved)
        entity.distance_moved = 0
      end

      # skipping removal of motel callbacks on changed movement strategy
      # as new callbacks will simply overwrite old

      # update the entity in the registry
      entity.location = loc
      registry.update(entity, :distance_moved, &with_id(entity.id))
    end

    nil
  }

  MOTEL_CALLBACK_METHODS = { :motel_callback => motel_callback }
end # module Manufactured::RJR

def dispatch_manufactured_rjr_motel_callback(dispatcher)
  m = Manufactured::RJR::MOTEL_CALLBACK_METHODS
  callbacks = ['motel::on_movement', 'motel::on_rotation']
  dispatcher.handle(callbacks, &m[:motel_callback])
  dispatcher.env callbacks, Manufactured::RJR
end
