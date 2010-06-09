# Motel simrpc adapter
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'simrpc'

module Motel

# Motel::Server defines a server endpoint which manages locations
# and responds to simrpc requests
class Server
  def initialize(args = {})
    simrpc_args = args
    simrpc_args[:id] = "location-server"

    # create a simprc node
    @simrpc_node = Simrpc::Node.new(simrpc_args)

    # register handlers for the various motel simrpc methods
    @simrpc_node.handle_method("get_location") { |location_id|
       Logger.info "received get location #{location_id} request"
       loc = nil
       begin
         loc = Runner.instance.locations.find { |loc| loc.id == location_id }
         # FIXME traverse all of loc's descendants, and if remote location
         # server is specified, send request to get child location, swapping
         # it in for the one thats there
       rescue Exception => e
         Logger.warn "get location #{location_id} failed w/ exception #{e}"
       end
       Logger.info "get location #{location_id} request returning #{loc}"
       loc
    }

    @simrpc_node.handle_method("create_location") { |location|
       Logger.info "received create location request"
       location = Location.new if location.nil?
       ret = location
       begin
         location.x = 0 if location.x.nil?
         location.y = 0 if location.y.nil?
         location.z = 0 if location.z.nil?

         # TODO decendants support w/ remote option (create additional locations on other servers)
         Runner.instance.run location

       rescue Exception => e
         Logger.warn "create location failed w/ exception #{e}"
         ret = nil
       end
       Logger.info "create location request created and returning #{ret.id}"
       ret
    }

    @simrpc_node.handle_method("update_location") { |location|
       Logger.info "received update location #{location.id} request"
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
           Logger.info "updating location #{location.id} with #{location}/#{location.movement_strategy}"
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
           Logger.warn "update location #{location.id} failed w/ exception #{e}"
           success = false
         end
       end
       Logger.info "update location #{location.id} returning #{success}"
       success
    }

    @simrpc_node.handle_method("subscribe_to_location_movement") { |client_id, location_id, min_distance, min_x, min_y, min_z|
       Logger.info "subscribe client #{client_id} to location #{location_id} movement request received"
       loc = Runner.instance.locations.find { |loc| loc.id == location_id  }
       success = true
       if loc.nil? 
         success = false
       else
         callback = Callbacks::Movement.new :min_distance => min_distance, :min_x => min_x, :min_y => min_y, :min_z => min_z,
                                            :handler => lambda { |location, d, dx, dy, dz|
           # send location to client
           @simrpc_node.send_method("location_moved", client_id, location, d, dx, dy, dz)
         }
         loc.movement_callbacks.push callback
       end
       Logger.info "subscribe client #{client_id} to location #{location_id} movement returning  #{success}"
       success
    }

    @simrpc_node.handle_method("subscribe_to_locations_proximity") { |client_id, location1_id, location2_id, max_distance, max_x, max_y, max_z|
       Logger.info "subscribe client #{client_id} to location #{location1_id}/#{location2_id} proximity request received"
       loc1 = Runner.instance.locations.find { |loc| loc.id == location1_id  }
       loc2 = Runner.instance.locations.find { |loc| loc.id == location2_id  }
       success = true
       if loc1.nil? || loc2.nil?
         success = false
       else
         callback = Callbacks::Proximity.new :to_location => loc2, :max_distance => max_distance, :max_x => max_x, :max_y => max_y, :max_z => max_z,
                                            :handler => lambda { |location1, location2|
           # send locations to client
           @simrpc_node.send_method("locations_proximity", client_id, location1, location2)
         }
         loc1.proximity_callbacks.push callback
       end
       Logger.info "subscribe client #{client_id} to location #{location1_id}/#{location2_id} proximity request returning  #{success}"
       success
    }
  end

  def join
     @simrpc_node.join
  end
end

# Client defines a client endpoint that performs
# a request against a Motel Server
class Client
  # Set to a callable object that will take a location and distance moved
  attr_writer :on_location_moved

  # Set to a callable object that will take two locations
  attr_writer :on_locations_proximity

  # Initialize the client with various args, all of which are passed onto Simrpc::Node constructor
  def initialize(args = {})
    simrpc_args = args
    simrpc_args[:destination] = "location-server"

    @simrpc_node =  Simrpc::Node.new(simrpc_args)
  end

  def join
     @simrpc_node.join
  end

  def request(target, *args)
     method_missing(target, *args)
  end

  # pass simrpc method requests right onto the simrpc node
  def method_missing(method_id, *args)
     # special case for subsscribe_to_location, 
     if method_id == :subscribe_to_location_movement
        # add simrpc node id onto args list
        args.unshift @simrpc_node.id

        # handle location updates from the server, & issue subscribe request
        @simrpc_node.handle_method("location_moved") { |location, d, dx, dy, dz| 
           Logger.info "location #{location.id} moved"
           @on_location_moved.call(location, d, dx, dy, dz) unless @on_location_moved.nil?
        }

     elsif method_id == :subscribe_to_locations_proximity
        # add simrpc node id onto args list
        args.unshift @simrpc_node.id

        # handle location proximity events from the server, & issue subscribe request
        @simrpc_node.handle_method("locations_proximity") { |location1, location2|
           Logger.info "location #{location1.id}/#{location2.id} proximity"
           @on_locations_proximity.call(location1, location2) unless @on_locations_proximity.nil?
        }
     end

     @simrpc_node.method_missing(method_id, *args)
  end
end

end
