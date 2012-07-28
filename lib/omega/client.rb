# Helper module to define omega clients / robots
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega

class ClientRequest
  attr_accessor :method_name
  attr_accessor :method_params

  def initialize(method_name, *params)
    @method_name   = method_name
    @method_params = params
  end
end

class Client
  def initialize(args = {})
    @args = args
    set_context(args)

    @@client_lock ||= Mutex.new
    @@requests    ||= []
    @@entities    ||= []
  end

  def set_context(context={})
    context.each { |k,v|
      instance_variable_set "@#{k}".intern, v
      add_entity v
    }
  end

  def invoke_callback(*params, &bl)
    instance_exec *params, &bl if block_given?
  end

  def register_callback(callback_method, &bl)
    RJR::Dispatcher.add_handler(callback_method) { |*args|
      instance_exec *args, &bl if block_given?
    }
  end

  def self.listen
    @@rjr_node.listen
  end

  def self.join
    @@rjr_node.join
  end

  def self.stop
    @@rjr_node.stop
  end

  def queue_request(method_name, *params)
    @@client_lock.synchronize{
      @@requests << ClientRequest.new(method_name, *params)
    }
  end

  def invoke_requests(selected_response = :first)
    @@session_id ||= nil

    responses = []
    @@client_lock.synchronize {
      @@rjr_node ||= RJR::AMQPNode.new :node_id => 'omega-' + Motel.gen_uuid, :broker => 'localhost'
      @@rjr_node.message_headers['session_id'] = @@session_id
      @@rjr_node.message_headers['source_node'] = @@rjr_node.node_id
      requests = Array.new(@@requests)
      @@requests.clear
      requests.each { |req|
        RJR::Logger.debug "Invoking #{req.method_name} with (#{req.method_params.join(", ")})"
        responses << @@rjr_node.invoke_request('omega-queue', req.method_name, *req.method_params)
      }
    }
    return responses.first if selected_response == :first
    return responses.last  if selected_response == :last
    return responses.find { |r| r.is_a?(selected_response) ||
                                (r.is_a?(Array) && r.find { |i| !i.is_a?(selected_response) }.nil?) }
    return responses
  end

  def self.session_id=(session_id)
    @@client_lock.synchronize {
      @@session_id=session_id
    }
  end

  def add_entity(entity)
    @@client_lock.synchronize {
      @@entities << entity unless @@entities.include?(entity)
    }
  end

  def remove_entity(entity)
    @@client_lock.synchronize {
      @@entities.delete(entity)
    }
  end

  def self.entities
    ret = []
    @@client_lock.synchronize {
      @@entities.each { |e| ret << e }
    }
    ret
  end

end # class Client

##############################

module DSL # works best if you "include 'Omega::DSL'"

def rand_name
  Omega::Names.rand_name
end

def gen_uuid
  Motel.gen_uuid
end

def rand_resource
  Omega::Resources.rand_resource
end

def rand_location(args={})
  Motel::Location.random args
end

def rand_ship_type
  Manufactured::Ship::SHIP_TYPES[rand(Manufactured::Ship::SHIP_TYPES.size)]
end

def rand_station_type
  Manufactured::Station::STATION_TYPES[rand(Manufactured::Station::STATION_TYPES.size)]
end

def rand_system
  systems = Omega::Client.entities.select { |entity|
    entity.is_a?(Cosmos::SolarSystem)
  }
  systems[rand(systems.size)]
end

def rand_galaxy_system(galaxy, used_systems=[])
  systems = Omega::Client.entities.select { |entity|
    entity.is_a?(Cosmos::SolarSystem) && entity.galaxy == galaxy &&
    !used_systems.include?(entity)
  }
  raise ArgumentError, "no more available systems" if systems.size == 0
  sys = systems[rand(systems.size)]
  used_systems << sys
  sys
end

def elliptical(args = {})
  return Motel::MovementStrategies::Elliptical.random args
end

def listen
  Omega::Client.listen
end

def join
  Omega::Client.join
end

def stop
  Omega::Client.stop
end

def login(id, args={})
  user = Users::User.new(args.merge({:id => id}))
  client = Omega::Client.new
  client.queue_request 'users::login', user
  session = client.invoke_requests(Users::Session)
  Omega::Client.session_id = session.id
  session
end

def user(id, args = {}, &bl)
  user = Users::User.new(args.merge({:id => id}))
  client = Omega::Client.new
  client.queue_request 'users::get_entity', 'with_id', id

  begin
    user = client.invoke_requests(Users::User)

  rescue Exception => e
    RJR::Logger.info "creating user #{user.id}"
    client.queue_request 'users::create_entity', user
    user = client.invoke_requests(Users::User)
  end

  # pass not returned by server, so need to set explicitly if we can
  user.password = args[:password]

  client.set_context :user => user
  client.invoke_callback user, &bl

  return user
end

def privilege(id, entity)
  raise ArgumentError, "user must not be nil" if @user.nil?

  client = Omega::Client.new
  client.queue_request 'users::add_privilege', @user.id, id, entity
  RJR::Logger.info "creating privilege #{id} on #{entity} for #{@user.id}"
end

def role(role)
  raise ArgumentError, "user must not be nil" if @user.nil?

  client = Omega::Client.new
  privilege_entities = Omega::Roles::ROLES[role]
  privilege_entities.each { |pe|
    client.queue_request 'users::add_privilege', @user.id, pe[0], pe[1]
  }
  RJR::Logger.info "creating role #{role} for #{@user.id}"
  nil
end

def alliance(id, args = {}, &bl)
  # TODO alliance member/entity propertires should accept 
  # interchangable ids / entity objects
  ualliance = Users::Alliance.new(args.merge({:id => id}))

  client = Omega::Client.new :alliance => ualliance
  client.queue_request 'users::create_entity', ualliance
  RJR::Logger.info "creating alliance #{ualliance.id}"
  client.invoke_callback ualliance, &bl
  client.invoke_requests(Users::Alliance)
end

def nearby_locations(location, distance)
  client = Omega::Client.new
  RJR::Logger.info "retrieving locations within #{distance} of #{location}"
  client.queue_request 'motel::get_locations', 'within', distance, 'of', location
  client.invoke_requests(Motel::Location)
end

def galaxy(id, &bl)
  gal = Cosmos::Galaxy.new :name => id

  client = Omega::Client.new :galaxy => gal
  RJR::Logger.info "retrieving galaxy #{id}"
  client.queue_request 'cosmos::get_entity', 'of_type', :galaxy, 'with_name', id
  begin
    ngal = client.invoke_requests(Cosmos::Galaxy)
    client.remove_entity(gal)
    client.set_context(:galaxy => ngal)
    client.invoke_callback ngal, &bl
    return ngal

  rescue Exception => e
    client.queue_request 'cosmos::create_entity', gal, :universe
    RJR::Logger.info "creating galaxy #{gal.name}"
    client.invoke_callback gal, &bl
    gal = client.invoke_requests(Cosmos::Galaxy)
  end

  return gal
end

def system(id, star_id = nil, args = {}, &bl)
  sys = Cosmos::SolarSystem.new(args.merge({:name => id, :galaxy => @galaxy}))
  star = Cosmos::Star.new :name => star_id, :solar_system => sys

  client = Omega::Client.new :system => sys, :star => star
  RJR::Logger.info "retrieving system #{id}"
  client.queue_request 'cosmos::get_entity', 'of_type', :solarsystem, 'with_name', id
  begin
    nsys = client.invoke_requests(Cosmos::SolarSystem)
    client.remove_entity(sys)
    client.set_context(:solarsystem => nsys)
    client.invoke_callback nsys, &bl
    #RJR::Logger.info "updating system #{id}"
    return nsys

  rescue Exception => e
    raise ArgumentError, "galaxy must not be nil" if @galaxy.nil?
    client.queue_request 'cosmos::create_entity', sys, @galaxy.name
    RJR::Logger.info "creating system #{sys.name}"
    unless star_id.nil?
      client.queue_request 'cosmos::create_entity', star, sys.name
      RJR::Logger.info "creating star #{star.name}"
    end
    client.invoke_callback sys, &bl
  end

  return sys
end

def system_entities(sys = nil)
  sys = @system if sys.nil?
  raise ArgumentError, "system must not be nil" if sys.nil?
  client = Omega::Client.new :system => sys
  client.queue_request 'manufactured::get_entities', 'under', sys.name
  RJR::Logger.info "getting entities under #{sys.name}"
  client.invoke_requests
end

def jump_gate(system, endpoint, args = {}, &bl)
  gate = Cosmos::JumpGate.new(args.merge({:solar_system => system, :endpoint => endpoint}))

  client = Omega::Client.new :jump_gate => gate
  client.queue_request 'cosmos::create_entity', gate, system.name
  RJR::Logger.info "creating gate from #{system.name} to #{endpoint.name}"
  client.invoke_callback gate, &bl
  client.invoke_requests
end

def asteroid(id, args={}, &bl)
  raise ArgumentError, "system must not be nil" if @system.nil?

  asteroid = Cosmos::Asteroid.new(args.merge({:name => id, :solar_system => @system}))

  client = Omega::Client.new :asteroid => asteroid
  client.queue_request 'cosmos::create_entity', asteroid, @system.name
  RJR::Logger.info "creating asteroid #{asteroid.name}"
  client.invoke_callback asteroid, &bl
  return asteroid
end

def resource(args = {}, &bl)
  raise ArgumentError, "asteroid must not be nil" if @asteroid.nil?

  resource = Cosmos::Resource.new(args)

  client = Omega::Client.new :resource => resource
  client.queue_request 'cosmos::set_resource', @asteroid.name, resource, args[:quantity]
  RJR::Logger.info "setting resource #{resource.id} on #{@asteroid.name}"
  client.invoke_callback resource, &bl
  return resource
end

def resource_sources(entity, args = {})
  raise ArgumentError, "entity must not be nil" if entity.nil?

  client = Omega::Client.new
  client.queue_request 'cosmos::get_resource_sources', entity.name
  RJR::Logger.info "getting resource_source for #{entity.name}"
  resource_sources = client.invoke_requests(Cosmos::ResourceSource)
  return resource_sources
end

def planet(id, args={}, &bl)
  plan = Cosmos::Planet.new(args.merge({:name => id, :solar_system => @system}))

  client = Omega::Client.new :planet => plan
  RJR::Logger.info "retrieving planet #{id}"
  client.queue_request 'cosmos::get_entity', 'of_type', :planet, 'with_name', id
  begin
    # FIXME if invoked within the context of something else (galaxy/system creation)
    #       this will return the wrong value (also w/ ship below)
    nplan = client.invoke_requests(Cosmos::Planet)
    client.remove_entity(plan)
    client.set_context(:planet => nplan)
    client.invoke_callback nplan, &bl
    #RJR::Logger.info "updating planet #{id}"
    return nplan

  rescue Exception => e
    raise ArgumentError, "system must not be nil" if @system.nil?

    client.queue_request 'cosmos::create_entity', plan, @system.name
    RJR::Logger.info "creating planet #{plan.name}"
    client.invoke_callback plan, &bl
    plan = client.invoke_requests(Cosmos::Planet)

  end

  return plan
end

def moon(id, args={}, &bl)
  raise ArgumentError, "planet must not be nil" if @planet.nil?

  mn = Cosmos::Moon.new(args.merge({:name => id, :planet => @planet}))

  client = Omega::Client.new :moon => mn
  client.queue_request 'cosmos::create_entity', mn, @planet.name
  RJR::Logger.info "creating moon #{mn.name}"
  client.invoke_callback mn, &bl
end

def ship(id, args={}, &bl)
  if id.is_a?(Hash)
    args = id
    id   = args[:id]
  end

  create_new = false
  sh = Manufactured::Ship.new(args.merge({:id => id}))
  client = Omega::Client.new

  if id
    RJR::Logger.info "retrieving ship #{id}"
    client.queue_request 'manufactured::get_entity', 'with_id', id
  elsif args.has_key?(:location_id)
    RJR::Logger.info "retrieving ship with #{args.inspect}"
    client.queue_request('manufactured::get_entity', 'of_type', 'Manufactured::Ship', 'with_location', args[:location_id])
  end

  begin
    sh = client.invoke_requests(Manufactured::Ship)

  rescue Exception => e
    unless id
      RJR::Logger.info "could not retrieve ship with #{args}"
      return nil
    end

    client.queue_request 'manufactured::create_entity', sh
    RJR::Logger.info "creating ship #{sh.id}"
    create_new = true
  end

  client.set_context(:ship => sh)
  client.invoke_callback sh, &bl

  client.invoke_requests(Manufactured::Ship) if create_new

  return sh
end

def station(id, args={}, &bl)
  st = Manufactured::Station.new(args.merge({:id => id}))

  client = Omega::Client.new :station => st
  RJR::Logger.info "retrieving station #{id} with #{args.inspect}"
  client.queue_request 'manufactured::get_entity', 'with_id', id

  begin
    nst = client.invoke_requests(Manufactured::Station)
    client.remove_entity(st)
    client.set_context(:station => nst)
    client.invoke_callback nst, &bl
    return nst
  
  rescue Exception => e
    client.queue_request 'manufactured::create_entity', st
    RJR::Logger.info "creating station #{st.id}"
    client.invoke_callback st, &bl
    client.invoke_requests(Manufactured::Station)
  end

  return st
end

def fleet(id, args={}, &bl)
  fl = Manufactured::Fleet.new(args.merge({:id => id}))

  client = Omega::Client.new :fleet => fl
  client.queue_request 'manufactured::create_entity', fl
  RJR::Logger.info "creating fleet #{fl.id}"
  client.invoke_callback fl, &bl
  client.invoke_requests(Manufactured::Fleet)
end


def subscribe_to(event, args = {}, &bl)
  @@handlers ||= {}
  case event
  when :movement
    raise ArgumentError, "ship or planet must not be nil" if @ship.nil? && @planet.nil?
    entity = @ship || @planet
    client = Omega::Client.new :entity => entity
    client.queue_request 'motel::track_movement', entity.location.id, args[:distance]
    RJR::Logger.info "subscribing to movement (#{args[:distance]}) of #{entity}"
    @@handlers[:on_movement] ||= {}
    @@handlers[:on_movement][entity.location.id] = bl
    client.register_callback "motel::on_movement" do |loc|
      @@handlers[:on_movement][loc.id].call loc
      nil
    end
    client.invoke_requests

  #when :proximity
  #when :entered_proximity
  #when :left_proximity

  when :attacked, :attacked_stop, :defended, :defended_stop, :destroyed, :resource_collected, :resource_depleted, :mining_stopped
    raise ArgumentError, "ship must not be nil" if @ship.nil?
    client = Omega::Client.new :ship => @ship
    client.queue_request 'manufactured::subscribe_to', @ship.id, event
    RJR::Logger.info "subscribing to #{event} on #{@ship}"
    @@handlers[:manufactured_event_occurred] ||= {}
    @@handlers[:manufactured_event_occurred][event.to_s] = bl
    client.register_callback "manufactured::event_occurred" do |*args|
      aevent = args.shift
      @@handlers[:manufactured_event_occurred][aevent].call *args
      nil
    end
    client.invoke_requests
  end
end

def clear_callbacks
  raise ArgumentError, "ship must not be nil" if @ship.nil?
  client = Omega::Client.new :ship => @ship
  client.queue_request 'motel::remove_callbacks', @ship.location.id
  client.queue_request 'manufactured::remove_callbacks', @ship.id
  RJR::Logger.info "removing callbacks on ship #{@ship}"
  client.invoke_requests
end

def move_to(location)
  raise ArgumentError, "ship or station must not be nil" if @ship.nil? && @station.nil?
  client = Omega::Client.new :ship => @ship, :station => @station
  entity = @ship || @station
  client.queue_request 'manufactured::move_entity', entity.id, location
  RJR::Logger.info "moving #{entity} to #{location}"
  client.invoke_requests
end

def follow(entity)
  raise ArgumentError, "ship must not be nil" if @ship.nil?
  client = Omega::Client.new :ship => @ship
  client.queue_request 'manufactured::follow_entity', @ship.id, entity.id, 10
  RJR::Logger.info "following #{entity} with #{@ship}"
  client.invoke_requests
end

def dock(ship, station)
  client = Omega::Client.new
  client.queue_request 'manufactured::dock', ship.id, station.id
  RJR::Logger.info "docking #{ship.id} at #{station.id}"
  client.invoke_requests
end

def undock(ship)
  client = Omega::Client.new
  client.queue_request 'manufactured::undock', ship.id
  RJR::Logger.info "undocking #{ship.id}"
  client.invoke_requests
end

def transfer_resource(from_entity, to_entity, resource_id, quantity)
  client = Omega::Client.new
  client.queue_request 'manufactured::transfer_resource', from_entity.id, to_entity.id, resource_id, quantity
  RJR::Logger.info "transferring #{quantity} of resource #{resource_id} from #{from_entity.id} to #{to_entity.id}"
  client.invoke_requests
end

def construct(entity_type, args={})
  raise ArgumentError, "station must not be nil" if @station.nil?
  client = Omega::Client.new :station => @station
  client.queue_request 'manufactured::construct_entity', @station.id, entity_type.to_s, args.to_a.flatten
  RJR::Logger.info "constructing #{entity_type} at #{@station.id} with args #{args}"
  client.invoke_requests(entity_type)
end

def construct_ship(args={})
  construct(Manufactured::Ship, args)
end

def construct_station(args={})
  construct(Manufactured::Station, args)
end

def start_mining(resource_source)
  raise ArgumentError, "ship must not be nil" if @ship.nil?
  client = Omega::Client.new :ship => @ship
  client.queue_request 'manufactured::start_mining', @ship.id, resource_source.entity.name, resource_source.resource.id
  RJR::Logger.info "mining #{resource_source} with #{@ship}"
  client.invoke_requests
end

def start_attacking(target)
  raise ArgumentError, "ship must not be nil" if @ship.nil?
  client = Omega::Client.new :ship => @ship
  client.queue_request 'manufactured::attack_entity', @ship.id, target.id
  RJR::Logger.info "attacking #{target.id} with #{@ship}"
  client.invoke_requests
end

end # module DSL

end # module Omega
