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

    @simrpc_node.handle_method("create_location") { |location_id|
       Logger.info "received create location #{location_id} request"
       success = true
       begin
         Runner.instance.run Location.new(:id => location_id)
         # TODO decendants support w/ remote option (create additional locations on other servers)
       rescue Exception => e
         Logger.warn "create location #{location_id} failed w/ exception #{e}"
         success = false
       end
       Logger.info "create location #{location_id} request returning #{success}"
       success
    }

    @simrpc_node.handle_method("update_location") { |location|
       Logger.info "received update location #{location.id} request"
       success = true
       if location.nil?
         success = false
       else
         rloc = Runner.instance.locations.find { |loc| loc.id == location.id  }
         begin
           Logger.info "updating location #{location.id} with #{location}/#{location.movement_strategy}"
           rloc.update(location)
         rescue Exception => e
           Logger.warn "update location #{location.id} failed w/ exception #{e}"
           success = false
         end
       end
       Logger.info "update location #{location.id} returning #{success}"
       success
    }

    @simrpc_node.handle_method("subscribe_to_location") { |location_id, client_id|
       Logger.info "subscribe client #{client_id} to location #{location_id}  request received"
       loc = Runner.instance.locations.find { |loc| loc.id == location_id  }
       success = true
       if loc.nil? 
         success = false
       else
         callback = Callbacks::Movement.new :handler => lambda { |location|
           # send location to client
           @simrpc_node.send_method("location_moved", client_id, location)
         }
         loc.movement_callbacks.push callback
       end
       Logger.info "subscribe client #{client_id} to location #{location_id}  returning  #{success}"
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
  # should be a callable object that takes a location to be
  # invoked when the server sends a location to the client
  attr_writer :on_location_received

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
     if method_id == :subscribe_to_location
        # add simrpc node id onto args list
        args.push @simrpc_node.id

        # handle location updates from the server, & issue subscribe request
        @simrpc_node.handle_method("location_moved") { |location| 
           Logger.info "location #{location.id} moved"
           @on_location_received.call(location) unless @on_location_received.nil?
        }
     end
     @simrpc_node.method_missing(method_id, *args)
  end
end

end
