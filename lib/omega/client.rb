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
    @args.each { |k,v|
      instance_variable_set "@#{k}".intern, v
    }
  end

  def invoke_callback(*params, &bl)
    instance_exec *params, &bl if block_given?
  end

  def queue_request(method_name, *params)
    @@requests ||= []
    @@requests << ClientRequest.new(method_name, *params)
  end

  def invoke_requests
    @@session_id ||= nil

    responses = []
    rjr_node = RJR::AMQPNode.new :node_id => 'seeder', :broker => 'localhost'
    rjr_node.message_headers['session_id'] = @@session_id
    @@requests.each { |req|
      RJR::Logger.debug "Invoking #{req.method_name} with (#{req.method_params.join(", ")})"
      responses << rjr_node.invoke_request('omega-queue', req.method_name, *req.method_params)
    }
    @@requests.clear
    responses.first
  end

  def self.session_id=(session_id)
    @@session_id=session_id
  end

  def add_entity(entity)
    @@entities ||= []
    @@entities << entity
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

def login(id, args={})
  user = Users::User.new(args.merge({:id => id}))
  client = Omega::Client.new
  client.queue_request 'users::login', user
  session = client.invoke_requests
  Omega::Client.session_id = session.id
  session
end


def user(id, args = {}, &bl)
  user = Users::User.new(args.merge({:id => id}))

  # TODO attempt to retrieve user b4 creating
  client = Omega::Client.new :user => user
  client.add_entity user
  client.queue_request 'users::create_entity', user
  RJR::Logger.info "creating user #{user.id}"
  client.invoke_callback user, &bl
  client.invoke_requests
end

def privilege(id, entity)
  raise ArgumentError, "user must not be nil" if @user.nil?

  client = Omega::Client.new
  client.queue_request 'users::add_privilege', @user.id, id, entity
  RJR::Logger.info "creating privilege #{id} on #{entity} for #{@user.id}"
end

def alliance(id, args = {}, &bl)
  # TODO alliance member/entity propertires should accept 
  # interchangable ids / entity objects
  ualliance = Users::Alliance.new(args.merge({:id => id}))

  client = Omega::Client.new :alliance => ualliance
  client.add_entity ualliance
  client.queue_request 'users::create_entity', ualliance
  RJR::Logger.info "creating alliance #{ualliance.id}"
  client.invoke_callback ualliance, &bl
  client.invoke_requests
end

def galaxy(id, &bl)
  gal = Cosmos::Galaxy.new :name => id

  client = Omega::Client.new :galaxy => gal
  client.add_entity gal
  client.queue_request 'cosmos::create_entity', gal, :universe
  RJR::Logger.info "creating galaxy #{gal.name}"
  client.invoke_callback gal, &bl
  client.invoke_requests
end

def system(id, star_id, args = {}, &bl)
  raise ArgumentError, "galaxy must not be nil" if @galaxy.nil?

  sys = Cosmos::SolarSystem.new(args.merge({:name => id, :galaxy => @galaxy}))
  star = Cosmos::Star.new :name => star_id, :solar_system => sys

  client = Omega::Client.new :system => sys
  client.add_entity sys
  client.add_entity star
  client.queue_request 'cosmos::create_entity', sys, @galaxy
  client.queue_request 'cosmos::create_entity', star, sys
  RJR::Logger.info "creating system #{sys.name}"
  RJR::Logger.info "creating star #{star.name}"
  client.invoke_callback sys, &bl
end

def jump_gate(system, endpoint, args = {}, &bl)
  gate = Cosmos::JumpGate.new(args.merge({:solar_system => system, :endpoint => endpoint}))

  client = Omega::Client.new :jump_gate => gate
  client.add_entity gate
  client.queue_request 'cosmos::create_entity', gate, system
  RJR::Logger.info "creating gate from #{system.name} to #{endpoint.name}"
  client.invoke_callback gate, &bl
end

def planet(id, args={}, &bl)
  raise ArgumentError, "system must not be nil" if @system.nil?

  plan = Cosmos::Planet.new(args.merge({:name => id, :solar_system => @system}))

  client = Omega::Client.new :planet => plan
  client.add_entity plan
  client.queue_request 'cosmos::create_entity', plan, @system
  RJR::Logger.info "creating planet #{plan.name}"
  client.invoke_callback plan, &bl
end

def moon(id, args={}, &bl)
  raise ArgumentError, "planet must not be nil" if @planet.nil?

  mn = Cosmos::Moon.new(args.merge({:name => id, :planet => @planet}))

  client = Omega::Client.new :moon => mn
  client.add_entity mn
  client.queue_request 'cosmos::create_entity', mn, @planet
  RJR::Logger.info "creating moon #{mn.name}"
  client.invoke_callback mn, &bl
end

def ship(id, args={}, &bl)
  sh = Manufactured::Ship.new(args.merge({:id => id}))

  client = Omega::Client.new :ship => sh
  client.add_entity sh
  client.queue_request 'manufactured::create_entity', sh
  RJR::Logger.info "creating ship #{sh.id}"
  client.invoke_callback sh, &bl
  client.invoke_requests
end

def station(id, args={}, &bl)
  st = Manufactured::Station.new(args.merge({:id => id}))

  client = Omega::Client.new :station => st
  client.add_entity st
  client.queue_request 'manufactured::create_entity', st
  RJR::Logger.info "creating station #{st.id}"
  client.invoke_callback st, &bl
  client.invoke_requests
end

def fleet(id, args={}, &bl)
  fl = Manufactured::Fleet.new(args.merge({:id => id}))

  client = Omega::Client.new :fleet => fl
  client.add_entity fl
  client.queue_request 'manufactured::create_entity', fl
  RJR::Logger.info "creating fleet #{fl.id}"
  client.invoke_callback fl, &bl
  client.invoke_requests
end


# TODO for entities planets / ships
#      for events movement, proximity (all 3), attacked/stop attacked/destroyed
def subscribe_to(entity, event, args = {})
end

end # module DSL

end # module Omega
