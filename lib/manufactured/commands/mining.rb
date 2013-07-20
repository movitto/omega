# Manufactured mining command definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'omega/server/command'

module Manufactured
module Commands

# Represents action of one {Manufactured::Ship} mining a {Cosmos::Resource}
#
# Invokes various Manufactured::Callback handlers upon various events.
#
# The callback events/types invoked include:
# * 'mining_stopped'     - invoked when miner stops mining with event, stopped reason, ship, and resource source as params. Reasons include:
# ** 'mining_distance_exceeded'
# ** 'ship_cargo_full'
# ** 'ship_docked'
# ** 'resource_depleted'
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
    mq = @ship.mining_quantity
    cs = @ship.cargo_space

    # try to mine it all
    @q  = @resource.quantity

    # the following selects the smallest amongst mq,cs,q

    # can't mine it all but can store what is mined
    if mq <= @q && mq <= cs
      # only mine what we can
      @q = mq

    # we can store less than what is mined and/or
    # less than what is in the resource
    elsif cs <= @q
      # only mine what can be stored
      @q = cs
    end

    # if ship is full, set quantity to 1 to stop
    # this mining command in checks below
    @q = 1 if @ship.cargo_space == 0

    Cosmos::Resource.new :id          => @resource.nil? ? nil : @resource.id,
                         :material_id => @resource.nil? ? nil : @resource.material_id,
                         :entity      => @resource.nil? ? nil : @resource.entity,
                         :quantity    => @q
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
    @error = false
  end

  def update(cmd)
    update_from(cmd, :resource)
    super(cmd)
  end

  def first_hook
    @ship.start_mining(@resource)
  end

  def before_hook
    # update ship location & cosmos resource/entity
     @ship = retrieve(@ship.id)

    # update location from motel
    @ship.location = invoke 'motel::get_location', 'with_id', @ship.location.id

     begin
       @resource = invoke 'cosmos::get_resource', @resource.id
     rescue Exception => e
       # if any problems retrieving resource, invalidate command
       @resource.quantity = 0
       @error = true
     end

     # retrieve entity regardless of resource retrieval errs
     #   (for use in last_hook below)
     @resource.entity = invoke 'cosmos::get_entity', 'with_id', @resource.entity_id
  end

  def after_hook
    # update ship and resources
    update_registry(@ship)
    invoke 'cosmos::set_resource', @resource
  end

  def last_hook
    @ship.stop_mining

    reason = ''
    r = gen_resource

    # ship & resource are too far apart or in different systems
    if (@ship.location.parent_id != r.entity.location.parent_id ||
       (@ship.location - r.entity.location) > @ship.mining_distance)
      reason = 'mining_distance_exceeded'

    # ship is at max capacity
    elsif (@ship.cargo_quantity + r.quantity) > @ship.cargo_capacity
      reason = 'ship_cargo_full'

    # ship has become docked
    elsif @ship.docked?
      reason = 'ship_docked'

    elsif r.quantity == 0
      reason = 'resource_depleted'
    end

    ::RJR::Logger.debug "ship #{@ship.id} cannot continue mining due to: #{reason}"
    run_callbacks @ship, 'mining_stopped', @resource, reason
  end

  def should_run?
    return false if @error
    r = gen_resource
    super && @ship.can_mine?(r) && @ship.can_accept?(r)
  end

  def run!
    super
    ::RJR::Logger.debug "invoking mining command #{@ship.id} -> #{@resource}"

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

    # run post-mining callbacks and update user attributes
    if resource_transferred
      run_callbacks(@ship, 'resource_collected',
                    @resource, r.quantity)
      invoke 'users::update_attribute', @ship.user_id,
              Users::Attributes::ResourcesCollected.id, r.quantity
    end
  end

  def remove?
    # remove if we cannot mine anymore
    return true if @error
    r = gen_resource
    !@ship.can_mine?(r) || !@ship.can_accept?(r)
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
