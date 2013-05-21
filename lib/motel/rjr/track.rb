# motel::track_movement,motel::track_rotation,
# motel::track_proximity, motel::track_stops,
# motel::remove_callbacks rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

track_movement = proc { |location_id, min_distance|
   loc = Runner.instance.locations.find { |loc| loc.id == location_id }
   raise Omega::DataNotFound, "location specified by #{location_id} not found" if loc.nil?

   raise ArgumentError, "min_distance must be an int or float > 0" unless (min_distance.is_a?(Integer) || min_distance.is_a?(Float)) && min_distance > 0

   # TODO add option to verify request is coming from authenticated source node which current connection was established on
   # TODO ensure that rjr_node_type supports persistant connections

   on_movement = 
     Callbacks::Movement.new :endpoint => @headers['source_node'],
                             :min_distance => min_distance,
                             :handler => lambda{ |loc, d, dx, dy, dz|
       begin
         if loc.restrict_view
           Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                                                      {:privilege => 'view', :entity => 'locations'}],
                                             :session   => @headers['session_id'])
         end
         @rjr_callback.invoke('motel::on_movement', loc)

       rescue Omega::PermissionError => e
         RJR::Logger.warn "client does not have privilege to view movement of #{loc.id}"
         loc.movement_callbacks.delete on_movement

       rescue RJR::Errors::ConnectionError => e
         RJR::Logger.warn "track_movement client disconnected"
         loc.movement_callbacks.delete on_movement

       rescue Exception => e
         RJR::Logger.warn "exception raised when invoking track_movmement callback: #{e}"
         loc.movement_callbacks.delete on_movement

       end
     }

   @rjr_node.on(:closed){ |node|
     Motel::Runner.instance.safely_run {
       loc.movement_callbacks.delete(on_movement)
     }
   }

   Motel::Runner.instance.safely_run {
     # TODO this ignores distance differences, do anything about this?
     old = loc.movement_callbacks.find { |m| m.endpoint_id == on_movement.endpoint_id }
     unless old.nil?
       loc.movement_callbacks.delete(old)
     end

     loc.movement_callbacks << on_movement
   }

   loc
}

track_proximity = proc { |location1_id, location2_id, event, max_distance|
   loc1 = Runner.instance.locations.find { |loc| loc.id == location1_id }
   loc2 = Runner.instance.locations.find { |loc| loc.id == location2_id }
   raise Omega::DataNotFound, "location specified by #{location1_id} not found" if loc1.nil?
   raise Omega::DataNotFound, "location specified by #{location2_id} not found" if loc2.nil?

   valid_events = ['proximity', 'entered_proximity', 'left_proximity']
   raise ArgumentError, "event must be one of #{valid_events.join(", ")}" unless valid_events.include?(event)
   raise ArgumentError, "max_distance must be an int or float > 0" unless (max_distance.is_a?(Integer) || max_distance.is_a?(Float)) && max_distance > 0

   # TODO add option to verify request is coming from authenticated source node which current connection was established on
   # TODO ensure that rjr_node_type supports persistant connections

   on_proximity =
     Callbacks::Proximity.new :endpoint => @headers['source_node'],
                              :to_location => loc2,
                              :event => event,
                              :max_distance => max_distance,
                              :handler => lambda { |location1, location2|
       begin
         if loc1.restrict_view
           Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc1.id}"},
                                                      {:privilege => 'view', :entity => 'locations'}],
                                           :session   => @headers['session_id'])
         end

         if loc2.restrict_view
           Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc2.id}"},
                                                    {:privilege => 'view', :entity => 'locations'}],
                                           :session   => @headers['session_id'])
         end

         @rjr_callback.invoke('motel::on_proximity', loc1, loc2)

       rescue Omega::PermissionError => e
         RJR::Logger.warn "client does not have privilege to view proximity of #{loc1.id}/#{loc2.id}"
         loc1.proximity_callbacks.delete on_proximity

       rescue RJR::Errors::ConnectionError => e
         RJR::Logger.warn "track_proximity client disconnected"
         loc1.proximity_callbacks.delete on_proximity

       rescue Exception => e
         RJR::Logger.warn "exception raised when invoking track_proximity callback: #{e}"
         loc1.proximity_callbacks.delete on_proximity

       end
     }

   @rjr_node.on(:closed){ |node|
     Motel::Runner.instance.safely_run {
       loc1.proximity_callbacks.delete(on_proximity)
     }
   }


   Motel::Runner.instance.safely_run {
     old = loc1.proximity_callbacks.find { |p| p.endpoint_id == on_proximity.endpoint_id }
     unless old.nil?
       loc1.proximity_callbacks.delete(old)
     end

     loc1.proximity_callbacks << on_proximity
   }

   [loc1, loc2]
}

track_rotation = proc { |location_id, min_rotation|
   loc = Runner.instance.locations.find { |loc| loc.id == location_id }
   raise Omega::DataNotFound, "location specified by #{location_id} not found" if loc.nil?

   raise ArgumentError, "min_rotation must be an float between 0 and 4*PI" unless min_rotation.is_a?(Float) && min_rotation > 0 && min_rotation < 4*Math::PI

   # TODO add option to verify request is coming from authenticated source node which current connection was established on
   # TODO ensure that rjr_node_type supports persistant connections

   on_rotation = 
     Callbacks::Rotation.new :endpoint => @headers['source_node'],
                             :min_rotation => min_rotation,
                             :handler => lambda{ |loc, da, dt, dp|
       begin
         if loc.restrict_view
           Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                                                      {:privilege => 'view', :entity => 'locations'}],
                                             :session   => @headers['session_id'])
         end
         @rjr_callback.invoke('motel::on_rotation', loc)

       rescue Omega::PermissionError => e
         RJR::Logger.warn "client does not have privilege to view rotation of #{loc.id}"
         loc.rotation_callbacks.delete on_rotation

       rescue RJR::Errors::ConnectionError => e
         RJR::Logger.warn "track_rotation client disconnected"
         loc.rotation_callbacks.delete on_rotation

       rescue Exception => e
         RJR::Logger.warn "exception raised when invoking track_rotation callback: #{e}"
         loc.rotation_callbacks.delete on_rotation

       end
     }

   @rjr_node.on(:closed){ |node|
     Motel::Runner.instance.safely_run {
       loc.rotation_callbacks.delete(on_rotation)
     }
   }

   Motel::Runner.instance.safely_run {
     # TODO this ignores rotation angle differences, do anything about this?
     old = loc.rotation_callbacks.find { |r| r.endpoint_id == on_rotation.endpoint_id }
     unless old.nil?
       loc.rotation_callbacks.delete(old)
     end

     loc.rotation_callbacks << on_rotation
   }

   loc
}

track_stops = proc { |location_id|
   loc = Runner.instance.locations.find { |loc| loc.id == location_id }
   raise Omega::DataNotFound, "location specified by #{location_id} not found" if loc.nil?

   # TODO add option to verify request is coming from authenticated source node which current connection was established on
   # TODO ensure that rjr_node_type supports persistant connections

   on_stopped =
     Callbacks::Stopped.new :endpoint => @headers['source_node'],
                             :handler => lambda{ |loc|
       begin
         if loc.restrict_view
           Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                                                      {:privilege => 'view', :entity => 'locations'}],
                                             :session   => @headers['session_id'])
         end
         @rjr_callback.invoke('motel::location_stopped', loc)

       rescue Omega::PermissionError => e
         RJR::Logger.warn "client does not have privilege to view movement of #{loc.id}"
         loc.stopped_callbacks.delete on_stopped

       rescue RJR::Errors::ConnectionError => e
         RJR::Logger.warn "track_movement client disconnected"
         loc.stopped_callbacks.delete on_stopped

       rescue Exception => e
         RJR::Logger.warn "exception raised when invoking track_movmement callback: #{e}"
         loc.stopped_callbacks.delete on_stopped

       end
     }

   @rjr_node.on(:closed){ |node|
     Motel::Runner.instance.safely_run {
       loc.stopped_callbacks.delete(on_stopped)
     }
   }

   Motel::Runner.instance.safely_run {
     old = loc.stopped_callbacks.find { |m| m.endpoint_id == on_stopped.endpoint_id }
     unless old.nil?
       loc.stopped_callbacks.delete(old)
     end

     loc.stopped_callbacks << on_stopped
   }

   loc
}


remove_callbacks = proc { |*args|
  location_id = args[0]
  callback_type = args.length > 1 ? args[1] : nil
  source_node = @headers['source_node']
  # TODO add option to verify request is coming from authenticated source node which current connection was established on

  loc = Runner.instance.locations.find { |loc| loc.id == location_id }
  raise Omega::DataNotFound, "location specified by #{location_id} not found" if loc.nil?
  Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                                             {:privilege => 'view', :entity => 'locations'}],
                                    :session   => @headers['session_id']) if loc.restrict_view

  raise ArgumentError, "callback_type must be nil, movement, proximity, rotation, or stopped" unless [nil, 'movement', 'proximity', 'rotation', 'stopped'].include?(callback_type)

  Motel::Runner.instance.safely_run {
    if callback_type.nil? || callback_type == 'movement'
      loc.movement_callbacks.reject!{ |mc| mc.endpoint_id == source_node }
    end

    if callback_type.nil? || callback_type == 'proximity'
      loc.proximity_callbacks.reject!{ |mc| mc.endpoint_id == source_node }
    end

    if callback_type.nil? || callback_type == 'rotation'
      loc.rotation_callbacks.reject!{ |rc| rc.endpoint_id == source_node }
    end

    if callback_type.nil? || callback_type == 'stopped'
      loc.stopped_callbacks.reject!{ |sc| sc.endpoint_id == source_node }
    end
  }
  loc
}

def dispatch_track(dispatcher)
  dispatcher.handle 'motel::track_movement',   &track_movement
  dispatcher.handle 'motel::track_proximity',  &track_proximity
  dispatcher.handle 'motel::track_rotation',   &track_rotation
  dispatcher.handle 'motel::track_stops',      &track_stops
  dispatcher.handle 'motel::remove_callbacks', &remove_callbacks
end
