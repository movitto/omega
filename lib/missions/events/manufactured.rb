# Missions Manufactured Event definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Missions
module Events

# An event this is spawed by another in the manufactured subsystem
class Manufactured < Missions::Event
  # Array of args received pertaining to the manufactured event
  attr_accessor :manufactured_event_args

  # Manufactured Event intializer
  def initialize(*manufactured_event_args)
    @manufactured_event_args = manufactured_event_args

    # generate event id from args
    # XXX not pretty but works for now
    manu_event = manufactured_event_args.first
    id =
      case manu_event
      when 'attacked_stopped','attacked'                       then
        manufactured_event_args[1].id

      when 'defended_stopped','defended','destroyed'           then
        manufactured_event_args[2].id

      when 'resource_depleted','resource_collected'            then
        # TODO also incoporate resource_source_id (param 2) ?
        manufactured_event_args[1].id

      when 'mining_stopped'                                    then
        # TODO also incoporate resource_source_id (param 3) ?
        manufactured_event_args[2].id

      when 'construction_complete','partial_construction'      then
        manufactured_event_args[1].id

      end
    id += "_" + manu_event

    super(:id => id, :timestamp => Time.now)
  end
end

end
end
