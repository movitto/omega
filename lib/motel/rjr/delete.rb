# motel::delete_location rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

# TODO option to disable this rjr method

require 'motel/rjr/init'

module Motel::RJR
# remove specified location from the registry
delete_location = proc { |loc_id|
  require_privilege(:registry  => user_registry,
                    :privilege => 'delete',
                    :entity    => 'locations')

  # retrieve location from registry
  rloc = registry.entity &with_id(loc_id)

  # ensure location was found
  raise DataNotFound, loc_id if rloc.nil?

  registry.delete &with_id(loc_id)

  nil
}

DELETE_METHODS = { :delete_location => delete_location }
end

def dispatch_motel_rjr_delete(dispatcher)
  m = Motel::RJR::DELETE_METHODS
  dispatcher.handle 'motel::delete_location', &m[:delete_location]
end
