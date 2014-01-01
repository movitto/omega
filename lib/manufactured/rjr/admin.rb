# manufactured rjr admin module
#
# Only included in admin mode
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the Apache License, Version 2.0

# TODO require superadmin role to run these methods
#      (role itself, not any privs specifically)

# unbridled entity update mechanism
admin_set = proc { |entity|
  # XXX special case, resolve foreign references
  if entity.is_a?(Manufactured::Ship) && entity.docked_at_id
    entity.docked_at = registry.find &with_id(entity.docked_at_id)
  end
  # TODO mining_id, attacking_id

  registry.update entity, &with_id(entity.id)
  nil
}

# unbridled entity callback execution mechanism
admin_run_callbacks = proc { |entity_id, *args|
  registry.safe_exec { |entities|
    e = entities.find { |e| e.id == entity_id }
    e.run_callbacks *args
  }
  nil
}

ADMIN_METHODS = { :set   => admin_set, :run_callbacks => admin_run_callbacks }

def dispatch_manufactured_rjr_admin(dispatcher)
  dispatcher.handle "manufactured::admin::set",
                     &ADMIN_METHODS[:set]

  dispatcher.handle "manufactured::admin::run_callbacks",
                     &ADMIN_METHODS[:run_callbacks]
end
