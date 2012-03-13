# Motel rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Motel

class RJRAdapter
  def self.init
    Motel::Runner.instance.start :async => true
  end

  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('get_all_locations') {
       RJR::Logger.info "received get all locations request"
       locations = []
       begin
         locations = Runner.instance.locations
       rescue Exception => e
         RJR::Logger.warn "get all locations failed w/ exception #{e}"
       end
       RJR::Logger.info "get all locations request returning #{locations}"
       locations
    }

    rjr_dispatcher.add_handler('get_location') { |location_id|
       RJR::Logger.info "received get location #{location_id} request"
       loc = nil
       begin
         loc = Runner.instance.locations.find { |loc| loc.id == location_id }
         # FIXME traverse all of loc's descendants, and if remote location
         # server is specified, send request to get child location, swapping
         # it in for the one thats there
       rescue Exception => e
         RJR::Logger.warn "get location #{location_id} failed w/ exception #{e}"
       end
       RJR::Logger.info "get location #{location_id} request returning #{loc}"
       loc
    }

    rjr_dispatcher.add_handler('create_location') { |location|
       RJR::Logger.info "received create location request"
       location = Location.new if location.nil?
       #location = Location.new location if location.is_a? Hash
       ret = location
       begin
         location.x = 0 if location.x.nil?
         location.y = 0 if location.y.nil?
         location.z = 0 if location.z.nil?

         # TODO decendants support w/ remote option (create additional locations on other servers)
         Runner.instance.run location

       rescue Exception => e
         RJR::Logger.warn "create location failed w/ exception #{e}"
         ret = nil
       end
       RJR::Logger.info "create location request created and returning #{ret.class} #{ret.to_json}"
       ret
    }

    rjr_dispatcher.add_handler("update_location") { |location|
       RJR::Logger.info "received update location #{location.id} request"
       success = true
       if location.nil?
         success = false
       else
         rloc = Runner.instance.locations.find { |loc| loc.id == location.id  }
         begin
           # store the old location coordinates for comparison after the movement
           old_coords = [location.x, location.y, location.z]

           # FIXME XXX big problem/bug here, client must always specify location.movement_strategy, else location constructor will set it to stopped
           # FIXME this should halt location movement, update location, then start it again
           RJR::Logger.info "updating location #{location.id} with #{location}/#{location.movement_strategy}"
           rloc.update(location)

           # FIXME trigger location movement & proximity callbacks (make sure to keep these in sync w/ those invoked the the runner)
           # right now we can't do this because a single simrpc node can't handle multiple sent message response, see FIXME XXX in lib/simrpc/node.rb
           #rloc.movement_callbacks.each { |callback|
           #  callback.invoke(rloc, *old_coords)
           #}
           #rloc.proximity_callbacks.each { |callback|
           #  callback.invoke(rloc)
           #}

         rescue Exception => e
           RJR::Logger.warn "update location #{location.id} failed w/ exception #{e}"
           success = false
         end
       end
       RJR::Logger.info "update location #{location.id} returning #{success}"
       success
    }

    rjr_dispatcher.add_callback('track_location') { |location_id, min_distance|
       RJR::Logger.info "received track location #{location_id} request"
       loc = nil
       begin
         loc = Runner.instance.locations.find { |loc| loc.id == location_id }
         on_movement = 
           Callbacks::Movement.new :min_distance => min_distance,
                                   :handler => lambda{ |loc, d, dx, dy, dz|
             begin
               @rjr_callback.invoke(loc)
             rescue RJR::Errors::ConnectionError => e
               RJR::Logger.warn "track_location client disconnected"
               loc.movement_callbacks.delete on_movement
             end
           }
         loc.movement_callbacks << on_movement
       rescue Exception => e
         RJR::Logger.warn "track location #{location_id} failed w/ exception #{e}"
       end
       RJR::Logger.info "track location #{location_id} request returning #{loc}"
       loc
    }

    rjr_dispatcher.add_callback('track_proximity') { |location1_id, location2_id, event, max_distance|
       RJR::Logger.info "received track proximity #{location1_id}/#{location2_id} request"
       RJR::Logger.info "track proximity #{location1_id}/#{location2_id} returning"
       begin
         loc1 = Runner.instance.locations.find { |loc| loc.id == location1_id }
         loc2 = Runner.instance.locations.find { |loc| loc.id == location2_id }
         on_proximity =
           Callbacks::Proximity.new :to_location => loc2,
                                    :event => event,
                                    :max_distance => max_distance,
                                    :handler => lambda { |location1, location2|
             begin
               @rjr_callback.invoke(loc1, loc2)
             rescue RJR::Errors::ConnectionError => e
               RJR::Logger.warn "track_proximity client disconnected"
               loc.proximity_callbacks.delete on_proximity
             end
           }
           loc1.proximity_callbacks << on_proximity
       rescue Exception => e
         RJR::Logger.warn "track proximity #{location1_id}/#{location2_id} failed w/ exception #{e}"
       end
       nil
    }
  end
end

end # module Motel
