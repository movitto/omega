# Motel simrpc adapter
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'simrpc'

module Motel

# Motel::Server defines a server endpoint which manages locations
# and responds to simrpc requests
class Server
  def initialize(args = {})
    # load and start the default location set
    Loader.Load

    # create a simprc node
    @simrpc_node = Simrpc::Node.new(:id => "location-server", 
                                    :schema_file => args[:schema_file])

    # register handlers for the various motel simrpc methods
    @simrpc_node.handle_method("get_location") { |location_id|
       Logger.info "received get location #{location_id} request"
       loc = nil
       begin
         loc = Runner.get.locations.find { |loc| loc.id == location_id }
       rescue Exception => e
         Logger.warn "get location #{location_id} failed w/ exception #{e}"
       end
       Logger.info "get location #{location_id} request returning #{loc}"
       loc
    }

    @simrpc_node.handle_method("register_location") { |location_id|
       Logger.info "received register location #{location_id} request"
       success = true
       begin
         num_locations = Loader.Load "id = #{location_id}"
         success = (num_locations == 1)
       rescue Exception => e
         Logger.warn "register location #{location_id} failed w/ exception #{e}"
         success = false
       end
       Logger.info "register location #{location_id} request returning #{success}"
       success
    }

    @simrpc_node.handle_method("save_location") { |location_id|
       Logger.info "received save location #{location_id} request"
       success = true
       begin
         loc = Runner.get.locations.find { |loc| loc.id == location_id }
         loc.save! unless loc.nil?
         success = !loc.nil?
       rescue Exception => e
         Logger.warn "save location #{location_id} failed w/ exception #{e}"
         success = false
       end
       Logger.info "save location #{location_id} request returning #{success}"
       success
    }

    @simrpc_node.handle_method("update_location") { |location|
       Logger.info "received update location #{location.id} request"
       success = true
       if location.nil?
         success = false
       else
         rloc = Runner.get.locations.find { |loc| loc.id == location.id  }
         begin
           unless location.movement_strategy.nil?
             if rloc.movement_strategy.type == location.movement_strategy.type
               Logger.info "updating location #{location.id}'s movement strategy with #{location.movement_strategy.to_h}"
               rloc.movement_strategy.update_attributes! location.movement_strategy.to_h
             else
               Logger.info "setting location #{location.id}'s movement strategy"
               location.movement_strategy.save!
               rloc.movement_strategy = location.movement_strategy
               rloc.save!
             end
           end
           Logger.info "update location #{location.id} with #{location.to_h}"
           rloc.update_attributes!(location.to_h)
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
       loc = Runner.get.locations.find { |loc| loc.id == location_id  }
       success = true
       if loc.nil? 
         success = false
       else
         loc.movement_strategy.movement_callbacks.push lambda { |location|
           # send location to client
           @simrpc_node.send_method("location_moved", client_id, location)
         }
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

  # Initialize the client with any number of params. These may include
  #   *  :schema_file location of the simrpc schema defintion
  def initialize(params = {})
    @schema_file               = params[:schema_file]
    @simrpc_node =  Simrpc::Node.new(:schema_file => @schema_file, :destination => "location-server")
    @on_location_received  = params[:on_location_received]

    # handle location updates from the server
    @simrpc_node.handle_method("location_moved") { |location|
       @on_location_received.call(location) unless @on_location_received.nil?
    }
  end

  # perform a motel request, with the specified params
  #   * :request_target => [:get, :register, :save, :update] specify request to send to server, this argument must be present
  #   * :location => <Location instance> - location to send to server, requires an id for all operations
  #   * :movement_strategy_type => <string> - of movement_strategy.type to send to server
  def request(params = {})
    request_target            = params[:request_target]
    location                  = params[:location]
    movement_strategy_type    = params[:movement_strategy_type]
    movement_strategy_encoded = params[:movement_strategy_encoded]


    if request_target == :get
      return @simrpc_node.get_location(location.id)

    elsif request_target == :register
      return @simrpc_node.register_location(location.id)

    elsif request_target == :save
      return @simrpc_node.save_location(location.id)

    elsif request_target == :update
      if movement_strategy_type.nil? && movement_strategy_encoded.nil?
        location.movement_strategy = nil
      elsif !movement_strategy_type.nil? && !movement_strategy_encoded.nil?
        # FIXME
        #movement_strategy = MovementStrategy.factory(movement_strategy_type).from_s(movement_strategy_encoded)
      elsif !movement_strategy_type.nil? 
        location.movement_strategy = MovementStrategy.factory(movement_strategy_type).new
      elsif !movement_strategy_encoded.nil? 
        # TODO
      end
      return @simrpc_node.update_location(location)

    elsif request_target == :subscribe
      return @simrpc_node.subscribe_to_location(location.id, @simrpc_node.id)

    end
  end

  # pass simrpc method requests right onto the simrpc node
  def method_missing(method_id, *args)
     # special case for subsscribe_to_location, 
     # add simrpc node id onto args list
     if method_id == :subscribe_to_location
        args.push @simrpc_node.id
     end
     @simrpc_node.method_missing(method_id, *args)
  end
end

end
