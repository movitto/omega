# Missions Manufactured Event definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/event'

module Missions
module Events

# An event this is spawed by another in the manufactured subsystem
class Manufactured < Omega::Server::Event
  # Array of args received pertaining to the manufactured event
  attr_accessor :manufactured_event_args

  # Helper method to generate id from entity / event
  def self.gen_id(entity_id, event)
    "#{entity_id}_#{event}"
  end

  # Manufactured Event intializer
  def initialize(*manufactured_event_args)
    if  manufactured_event_args.first.is_a?(Hash)
      if manufactured_event_args.first.has_key?('manufactured_event_args')
        manufactured_event_args =
          manufactured_event_args.first['manufactured_event_args'].flatten
      else
        super(manufactured_event_args.first)
        return
      end
    end

    @manufactured_event_args = manufactured_event_args

    # generate event id from args
    # TODO right now we're just taking care of cases we need,]
    # add support for more manu events as they are required
    manu_event = manufactured_event_args.first
    entity_id =
      case manu_event
      when 'attacked'            then
        manufactured_event_args[1].id

      when 'destroyed_by'        then
        manufactured_event_args[1].id

      when 'resource_collected'  then
        manufactured_event_args[1].id

      when 'transferred_to'      then
        manufactured_event_args[1].id

      when 'collected_loot'      then
        manufactured_event_args[1].id

      end
    id = self.class.gen_id(entity_id, manu_event)

    super(:id => id, :timestamp => Time.now)
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        json_data.merge({:manufactured_event_args => @manufactured_event_args})
    }.to_json(*a)
  end
end

end
end
