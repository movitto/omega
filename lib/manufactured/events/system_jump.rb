# Manufactured System Jump Event Definition
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/event'

module Manufactured
module Events

class SystemJump < Omega::Server::Event
  TYPE = :system_jump

  # Entity which made the jump.
  # Entity's parent property will be the new system it is in
  attr_accessor :entity

  # System which entity jumped from
  attr_accessor :old_system

  # System Jump Event intializer
  def initialize(args={})
    attr_from_args args, :old_system => nil,
                         :entity     => nil
    id = "#{TYPE}-#{entity ? entity.id : nil}"
    super(:id => id, :type => TYPE)
  end

  def event_args
    [entity, old_system]
  end

  # Assuming we're only getting Manufactured::EventHandler instances here
  def trigger_handler?(handler)
    specifier = handler.event_args[0]
    target    = handler.event_args[1]

    case specifier
    when 'to'
      entity.parent_id == target
    when 'from'
      old_system.id == target
    else
      false
    end
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:old_system => @old_system, :entity => @entity}
    }.to_json(*a)
  end
end

end # module Events
end # module Manufactured
