# Mission Event Handler DSL
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'missions/dsl/helpers'

module Missions
module DSL

# Mission related event handlers
# XXX rename these methods
module EventHandler
  include Helpers

  def self.on_event_create_entity(args={})
    event       = args[:event]       || args['event']
    entity_type = args[:entity_type] || args['entity_type']
    id          = args[:id]          || args['id']
    case event
    when 'registered_user' then
      proc { |event|
        args[:id]      = id || Motel.gen_uuid
        args[:user_id] = event.users_event_args[1].id
        entity = entity_type == 'Manufactured::Ship' ?
            Manufactured::Ship.new(args) :
            Manufactured::Station.new(args)

        # TODO only if ship does not exist
        node.invoke('manufactured::create_entity', entity)
      }

    else
      nil

    end
  end

  def self.on_event_add_role(args={})
    event = args[:event] || args['event']
    role  = args[:role]  || args['role']
    case event
    when 'registered_user' then
      proc { |event|
        user_id = event.users_event_args[1].id
        node.invoke('users::add_role', user_id, role)
      }
    else
      nil
    end
  end

end # module EventHandler
end # module DSL
end # module Missions
