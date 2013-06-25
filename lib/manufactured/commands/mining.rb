# Manufactured mining command definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'omega/server/command'

module Manufactured
module Commands

# Represents action of one {Manufactured::Ship} mining a {Cosmos::ResourceSource}
#
# Invokes various Manufactured::Callback handlers upon various events.
#
# The callback events/types invoked include:
# * 'resource_depeleted' - invoked when resource source quantity becomes <= 0 with event, miner, and resource source as params
# * 'mining_stopped'     - invoked when miner stops mining with event, stopped reason, ship, and resource source as params. Reasons include:
# ** 'mining_distance_exceeded'
# ** 'ship_cargo_full'
# ** 'ship_docked'
# ** 'resource_depleted' (also invokes 'resource_depeleted' callback)
# * 'resource_collected' - invoked when miner collects the resource from the source, with event, miner, resource source, and quantity mined during this operation as params
class Mining < Omega::Server::Command
  include Omega::Server::CommandHelpers

  # Mining {Manufactured::Ship} ship
  attr_accessor :ship

  # {Cosmos::Resource} being mined
  attr_accessor :resource

  # Return the unique id of this mining command.
  #
  # Currently a ship may only mine one source at a time,
  # TODO incorporate multiple resources into this
  def id
    id = @ship.nil? ? "" : @ship.id.to_s
    "mining-cmd-#{id}"
  end

  private

  # internal helper, generate a new resource
  def gen_resource
    # if resource has less than mining_quantity only transfer that amount
    @q = @ship.nil? ? 0 : @ship.mining_quantity
    @q = @resource.quantity unless @resource.nil? || @resource.quantity >= @q

    Cosmos::Resource.new :id       => @resource.nil? ? nil : @resource.id,
                         :entity   => @resource.nil? ? nil : @resource.entity,
                         :quantity => @q
  end

  public

  # Manufactured::Commands::Mining initializer
  # @param [Hash] args hash of options to initialize mining command with
  # @option args [Manufactured::Ship] :ship miner ship
  # @option args [Cosmos::Resource] :resource resource source being mined
  def initialize(args = {})
    attr_from_args args, :ship  => nil,
                         :resource => nil
    super(args)
  end

  def first_hook
    @ship.start_mining(@resource)
  end

  def before_hook
    # update ship location & cosmos resource/entity
     @ship = retrieve(@ship.id)
     @resource = invoke 'cosmos::get_resource', 'with_id', @resource.id
     @resource.entity = invoke 'cosmos::get_entity', 'with_id', @ship.id
  end

  def after_hook
    # update ship and resources
    update_registry(@ship)
    invoke 'cosmos::set_resource', @resource
    # TODO
    #node.invoke('users::update_attribute', @ship.user_id,
    #            Users::Attributes::ResourcesCollected.id, @q)
  end

  def last_hook
    @ship.stop_mining

    reason = ''

    # ship & resource are too far apart or in different systems
    if (@ship.location.parent.id != @resource.entity.location.parent.id ||
       (@ship.location - @resource.entity.location) > @ship.mining_distance)
      reason = 'mining_distance_exceeded'

    # ship is at max capacity
    elsif (@ship.cargo_quantity + @ship.mining_quantity) >= @ship.cargo_capacity
      reason = 'ship_cargo_full'

    # ship has become docked
    elsif @ship.docked?
      reason = 'ship_docked'

    elsif @resource.quantity <= 0
      ::RJR::Logger.debug "#{@ship.id} depleted resource #{@resource.id}"
      @ship.run_callbacks('resource_depleted', @ship, @resource)
      reason = 'resource_depleted'
    end

    ::RJR::Logger.debug "ship #{@ship.id} cannot continue mining due to: #{reason}"
    run_callbacks @ship, 'mining_stopped', reason, @ship, @resource
  end

  def should_run?
    r = gen_resource
    super && @ship.can_mine?(r) && @ship.can_accept?(r)
  end

  def run!
    super
    ::RJR::Logger.debug "invoking mining command #{@ship.id} -> #{@resource.id}"

    r = gen_resource
    removed_resource = false
    resource_transferred = false
    begin
      @resource.quantity -= r.quantity
      removed_resource = true
      @ship.add_resource r
      resource_transferred = true
    rescue Exception => e
    ensure
      @resource.quantity += r.quantity if  removed_resource &&
                                          !resource_transferred
    end

    
    run_callbacks(@ship, 'resource_collected',
                  @ship, @resource, r.quantity) if resource_transferred
  end

   # Convert command to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:ship => ship,
          :resource => resource}.merge(cmd_json)
     }.to_json(*a)
   end

end # class Mining
end # module Commands
end # module Omega
