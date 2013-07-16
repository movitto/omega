# motel::create_location rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/rjr/init'

module Motel::RJR
# create specified location in the registry
create_location = proc { |loc|
  # require create locations
  require_privilege(:registry  => user_registry,
                    :privilege =>      'create',
                    :entity    =>   'locations')

  # ensure param is valid location
  raise ValidationError, loc unless loc.is_a?(Motel::Location) && loc.valid?

  # filter properties not able to be set by user
# FIXME XXX interim hack to allow id to be set, autogenerate here or in registry
  loc = filter_properties(loc, :allow =>
          [:id, :parent_id, :restrict_view, :x, :y, :z,
           :orientation_x, :orientation_y, :orientation_z,
           :movement_strategy])

  # store location, throw error if not added
  added = registry << loc
  raise OperationError, "#{loc.id} already exists" if !added

  # return loc
  loc
}

CREATE_METHODS = { :create_location => create_location }
end

def dispatch_motel_rjr_create(dispatcher)
  m = Motel::RJR::CREATE_METHODS
  dispatcher.handle 'motel::create_location', &m[:create_location]
end
