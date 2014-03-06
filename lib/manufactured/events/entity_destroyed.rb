# Manufactured Entity Destroyed Event Definition
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/event'

module Manufactured
module Events

class EntityDestroyed < Omega::Server::Event
  TYPE = :entity_destroyed

  # Entity which was destroyed
  attr_accessor :entity

  # TODO also include entity which destroyed this one?

  # Entity Destroyed Event intializer
  def initialize(args={})
    attr_from_args args, :entity => nil
    id = "#{TYPE}-#{entity ? entity.id : nil}"
    super(:id => id, :type => TYPE.to_s)
  end

  def event_args
    [entity]
  end

  # Assuming we're only getting Manufactured::EventHandler instances here
  def trigger_handler?(handler)
    # TODO right now always return true, should allow handler
    # to specify filters which to match entities with
    true
  end

  def json_data
    super.merge({:entity => entity})
  end
end # class EntityDestroyed

end # module Events
end # module Manufactured
