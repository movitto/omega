# motel::create_location rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

create_location = proc { |location|
  Users::Registry.require_privilege(:privilege => 'create', :entity => 'locations',
                                    :session   => @headers['session_id'])

  raise ArgumentError, "#{new_location} must be a location" unless new_location.is_a?(Motel::Location)

  # TODO remove this initialization from here (or at least some of it)
  new_location.x = 0 unless new_location.x.is_a?(Integer) || new_location.x.is_a?(Float)
  new_location.y = 0 unless new_location.y.is_a?(Integer) || new_location.y.is_a?(Float)
  new_location.z = 0 unless new_location.z.is_a?(Integer) || new_location.z.is_a?(Float)
  new_location.movement_strategy = Motel::MovementStrategies::Stopped.instance unless new_location.movement_strategy.kind_of?(Motel::MovementStrategy)

  new_location.movement_callbacks  = []
  new_location.proximity_callbacks = []
  new_location.children = []


  unless new_location.parent_id.nil?
    # if parent.nil? throw error?
    parent = Runner.instance.locations.find { |loc| loc.id == new_location.parent_id }
    Motel::Runner.instance.safely_run {
      parent.add_child(new_location) unless parent.nil?
      new_location.parent = parent
    }
  end

  # id gets set here
  # if id exists, throw error? or invoke update_location?
  Runner.instance.run new_location unless Runner.instance.has_location?(new_location.id)

  new_location
}

def dispatch_create(dispatcher)
  dispatcher.handle 'motel::create_location', &create_location
end
