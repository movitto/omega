# motel::create_location rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

include Omega::Server::DSL

create_location = proc { |loc|
  # require create locations
  require_privilege(:privilege => 'create', :entity => 'locations')

  # ensure param is valid location
  raise ValidationError, loc unless loc.is_a?(Motel::Location) && loc.valid?

  # filter properties not able to be set by user
  loc = filter_properties(loc, :allow => [:x, :y, :z, :parent_id])

  # store location, throw error if not added
  added = Registry.instance.add_if loc { |r|
    r.entities.find { |e| e.id == loc.id }.nil?
  }
  raise OperationError, "#{loc.id} already exists" if !added

  # return loc
  loc
}

def dispatch_create(dispatcher)
  dispatcher.handle 'motel::create_location', &create_location
end
