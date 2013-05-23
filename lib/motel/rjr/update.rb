# motel::update_location rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

update_location = proc { |loc|
  # ensure param is valid location / has valid id
  raise ValidationError, loc unless loc.is_a?(Motel::Location) &&
                                    loc.valid? && !loc.id.nil?

  # retrieve location from registry
  rloc = Registry.instance.entities.find { |l| l.id == loc.id}
  raise DataNotFound, loc.id if rloc.nil?

  # ensure user has permission to modify location
  if rloc.restrict_modify
    require_privilege \
      :any => [{:privilege => 'modify', :entity => "location-#{rloc.id}"},
               {:privilege => 'modify', :entity => 'locations'}])
  end

  # filter properties not able to be set by user
  loc = filter_properties(loc, :allow => [:x, :y, :z, :parent_id, :movement_strategy])

  # update the location
  RJR::Logger.info "updating location #{rloc}"
  #stopping = !rloc.ms.is_a?(Stopped) && loc.ms.is_a?(Stopped)
  Registry.instance.update(rloc, loc)
  #rloc.raise(:stopped) if stopping

  # return the location
  loc
}

def dispatch_update_location(dispatcher)
  dispatcher.handle "motel::update_location", &update_location
end
