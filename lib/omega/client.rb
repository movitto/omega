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

  def queue_request(method_name, *params)
    @@requests ||= []
    @@requests << ClientRequest.new(method_name, *params)
  end

  def invoke_requests(selected_response = :first)
    @@session_id ||= nil

    responses = []
    @@rjr_node ||= RJR::AMQPNode.new :node_id => 'seeder', :broker => 'localhost'
    @@rjr_node.message_headers['session_id'] = @@session_id
    requests = Array.new(@@requests)
    @@requests.clear
    requests.each { |req|
      RJR::Logger.debug "Invoking #{req.method_name} with (#{req.method_params.join(", ")})"
      responses << @@rjr_node.invoke_request('omega-queue', req.method_name, *req.method_params)
    }
    return responses.first if selected_response == :first
    return responses.last  if selected_response == :last
    return responses.find { |r| r.is_a?(selected_response) }
    return responses
  end

  def self.session_id=(session_id)
    @@session_id=session_id
  end

  def add_entity(entity)
    @@entities ||= []
    @@entities << entity unless @@entities.include?(entity)
  end

  def remove_entity(entity)
    @@entities.delete(entity)
  end

  def self.entities
    @@entities
  end

end # class Client

##############################

module DSL # works best if you "include 'Omega::DSL'"

def rand_name
  Omega::Names.rand_name
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

  # TODO attempt to retrieve user b4 creating
  client = Omega::Client.new :user => user
  client.queue_request 'users::create_entity', user
  RJR::Logger.info "creating user #{user.id}"
  client.invoke_callback user, &bl
  client.invoke_requests(Users::User)
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
  privilege_entities = Omega::Client::Roles::ROLES[role]
  privilege_entities.each { |pe|
    client.queue_request 'users::add_privilege', @user.id, pe[0], pe[1]
  }
  RJR::Logger.info "creating role #{role} for #{@user.id}"
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

def galaxy(id, &bl)
  gal = Cosmos::Galaxy.new :name => id

  client = Omega::Client.new :galaxy => gal
  client.queue_request 'cosmos::create_entity', gal, :universe
  RJR::Logger.info "creating galaxy #{gal.name}"
  client.invoke_callback gal, &bl
  client.invoke_requests(Cosmos::Galaxy)
end

def system(id, star_id, args = {}, &bl)
  raise ArgumentError, "galaxy must not be nil" if @galaxy.nil?

  sys = Cosmos::SolarSystem.new(args.merge({:name => id, :galaxy => @galaxy}))
  star = Cosmos::Star.new :name => star_id, :solar_system => sys

  client = Omega::Client.new :system => sys, :star => star
  client.queue_request 'cosmos::create_entity', sys, @galaxy.name
  client.queue_request 'cosmos::create_entity', star, sys.name
  RJR::Logger.info "creating system #{sys.name}"
  RJR::Logger.info "creating star #{star.name}"
  client.invoke_callback sys, &bl
end

def jump_gate(system, endpoint, args = {}, &bl)
  gate = Cosmos::JumpGate.new(args.merge({:solar_system => system, :endpoint => endpoint}))

  client = Omega::Client.new :jump_gate => gate
  client.queue_request 'cosmos::create_entity', gate, system.name
  RJR::Logger.info "creating gate from #{system.name} to #{endpoint.name}"
  client.invoke_callback gate, &bl
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

def planet(id, args={}, &bl)
  plan = Cosmos::Planet.new(args.merge({:name => id, :solar_system => @system}))

  client = Omega::Client.new :planet => plan
  RJR::Logger.info "retrieving planet #{id}"
  client.queue_request 'cosmos::get_entity', :planet, id
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
  sh = Manufactured::Ship.new(args.merge({:id => id}))

  client = Omega::Client.new :ship => sh
  RJR::Logger.info "retrieving ship #{id}"
  client.queue_request 'manufactured::get_entity', id
  begin
    nsh = client.invoke_requests(Manufactured::Ship)
    client.remove_entity(sh)
    client.set_context(:ship => nsh)
    client.invoke_callback nsh, &bl
    #RJR::Logger.info "updating ship #{id}"
    return nsh

  rescue Exception => e
    client.queue_request 'manufactured::create_entity', sh
    RJR::Logger.info "creating ship #{sh.id}"
    client.invoke_callback sh, &bl
    client.invoke_requests(Manufactured::Ship)

  end

  return sh
end

def station(id, args={}, &bl)
  st = Manufactured::Station.new(args.merge({:id => id}))

  client = Omega::Client.new :station => st
  client.queue_request 'manufactured::create_entity', st
  RJR::Logger.info "creating station #{st.id}"
  client.invoke_callback st, &bl
  client.invoke_requests(Manufactured::Station)
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
  case event
  when :movement
    raise ArgumentError, "ship or planet must not be nil" if @ship.nil? && @planet.nil?
    entity = @ship || @planet
    client = Omega::Client.new :entity => entity
    client.queue_request 'track_movement', entity.location.id, args[:distance]
    RJR::Logger.info "subscribing to movement (#{args[:distance]}) of #{entity}"
    client.register_callback "on_movement", &bl
    client.invoke_requests

  #when :proximity
  #when :entered_proximity
  #when :left_proximity

  when :attacked, :attacked_stopped, :destroyed
    raise ArgumentError, "ship must not be nil" if @ship.nil?
    client = Omega::Client.new :ship => @ship
    client.queue_request 'manufactured::subscribe_to', @ship, event
    RJR::Logger.info "subscribing to #{event} on #{@ship}"
    client.register_callback "manufactured::event_occurred", &bl
    client.invoke_requests

  end
end

end # module DSL

end # module Omega
