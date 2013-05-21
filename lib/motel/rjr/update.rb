# motel::update_location rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

update_location = proc { |location|
  raise ArgumentError, "#{location} must be a location with valid id" unless location.is_a?(Motel::Location) && !location.id.nil?

  rloc = Runner.instance.locations.find { |loc| loc.id == location.id  }
  raise Omega::DataNotFound, "location specified by #{location.id} not found" if rloc.nil?

  if rloc.restrict_modify
    Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "location-#{rloc.id}"},
                                               {:privilege => 'modify', :entity => 'locations'}],
                                      :session   => @headers['session_id'])
  end

  # store the old location coordinates for comparison after the movement
  old_coords = [location.x, location.y, location.z]

  # adjust location heirarchy
  if (rloc.parent_id != location.parent_id)
    new_parent = Runner.instance.locations.find { |loc| loc.id == location.parent_id  }
    Motel::Runner.instance.safely_run {
      new_parent.add_child(rloc) unless new_parent.nil?
    }
  end

  # setup attributes which should not be overwritten
  location.parent = rloc.parent
  location.x = 0 unless location.x.is_a?(Integer) || location.x.is_a?(Float)
  location.y = 0 unless location.y.is_a?(Integer) || location.y.is_a?(Float)
  location.z = 0 unless location.z.is_a?(Integer) || location.z.is_a?(Float)
  location.movement_strategy = Motel::MovementStrategies::Stopped.instance unless location.movement_strategy.kind_of?(Motel::MovementStrategy)

  # client should explicity set movement_strategy on location to nil to keep movement strategy
  RJR::Logger.info "updating location #{location.id} with #{location}/#{location.movement_strategy}"
  Motel::Runner.instance.safely_run {
    stopping = (rloc.movement_strategy != Motel::MovementStrategies::Stopped.instance) &&
               (location.movement_strategy == Motel::MovementStrategies::Stopped.instance)
    rloc.update(location)

    # if changing movement_strategy to stopped from another,
    # trigger 'stopped' callbacks
    # TODO change this into a more generic 'movement strategy changed' callback mechanism
    if stopping
      rloc.stopped_callbacks.each { |callback|
        callback.invoke(rloc);
      }
    end

    # TODO invoke movement/rotation/proximity callbacks as appropriate
  }

  location
}

def dispatch_update_location(dispatcher)
  dispatcher.handle "motel::update_location", &update_location
end
