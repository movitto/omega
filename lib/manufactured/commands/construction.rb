# Manufactured construction command definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/command'

module Manufactured
module Commands

# Represents action of one {Manufactured::Station} constructing another
# manufactured entity.
#
# Checking of resources & the actual construction (eg call to station.construct)
# should be done prior to invoking this, this will simulate a construction delay
# for a parameterized durition invoking the registered callbacks on the way.
# (TODO we may want to revisit this at some point)
#
# Invokes various Manufactured::Callback handlers upon various events.
# The callback events/types invoked include:
# * 'partial_construction'   - invoked upon every iteration of the construction cycle w/ the given fraction of construction completed
# * 'construction_complete'  - invoked when construction is fully completed
class Construction < Omega::Server::Command
  # Station {Manufactured::Station} station
  attr_accessor :station

  # {Manufactured::Entity entity} constructed
  attr_accessor :entity

  # Bool indicating if construction is completed
  attr_accessor :completed

  # Return the unique id of this construction command.
  def id
    sid = @station.nil? ? "" : @station.id
    eid = @entity.nil? ? "" : @entity.id
    "#{sid}-#{eid}"
  end

  # Manufactured::Commands::Construction initializer
  #
  # @param [Hash] args hash of options to initialize mining command with
  # @option args [Manufactured::Station] :station constructing station
  # @option args [Manufactured::Entity] :entity entity constructe
  def initialize(args = {})
    attr_from_args args, :station   => nil,
                         :entity    => nil,
                         :completed => false
    super(args)
  end

  def should_run?
    super && !self.completed
  end

  def run!
    RJR::Logger.debug "invoking construction cycle #{@station.id} -> #{@entity.id}"

    t = Time.now
    @last_ran_at ||= Time.now
    const_time = @entity.class.construction_time(@entity.type)
    total_time = t - @last_ran_at

    self.completed = (total_time >= const_time)

    # set last_ran_at after time check
    super

    if self.completed
      @station.run_callbacks 'construction_complete', @station, @entity

    else
      percentage = total_time / const_time
      @station.run_callbacks 'partial_construction', @station, @entity, percentage
    end
  end

   # Convert command to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:station => station,
          :entity  => entity}.merge(cmd_json)
     }.to_json(*a)
   end


end # class Construction
end # module Commands
end # module Omega
