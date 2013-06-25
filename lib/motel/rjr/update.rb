# motel::update_location rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/rjr/init'
require 'rjr/common' # for logger

module Motel::RJR
# update location specified by id
update_location = proc { |loc|
  # ensure param is valid location / has valid id
  raise ValidationError, loc unless loc.is_a?(Motel::Location) &&
                                    loc.valid? && !loc.id.nil?

  # retrieve location from registry
  rloc = registry.entity &with_id(loc.id)

  # ensure location was found
  raise DataNotFound, loc.id if rloc.nil?

  # ensure user has permission to modify location
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'modify', :entity => "location-#{rloc.id}"},
     {:privilege => 'modify', :entity => 'locations'}] if rloc.restrict_modify

  # filter properties not able to be set by user
  # XXX id marked as updatable so as to preserve in return value
  loc = filter_properties(loc, :allow =>
    [:id, :x, :y, :z, :parent_id, :movement_strategy, :next_movement_strategy])

  # TODO pause the location first?

  # update the location
  ::RJR::Logger.info "updating location #{rloc}"
  registry.update(loc, &with_id(rloc.id))

  # return the location
  loc
}

UPDATE_METHODS = { :update_location => update_location }
end

def dispatch_motel_rjr_update(dispatcher)
  m = Motel::RJR::UPDATE_METHODS
  dispatcher.handle "motel::update_location", &m[:update_location]
end
