# Motel rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'active_support/inflector'

module Cosmos

class RJRAdapter
  def self.init
    #Cosmos::Registry.instance.init
  end

  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('create_entity'){ |entity, parent|
       Users::Registry.require_privilege(:privilege => 'create', :entity => 'cosmos_entities',
                                         :session   => @headers['session_id'])

       parent_type = parent.is_a?(String) ?
                         parent.intern :
                         parent.class.to_s.downcase.underscore.split('/').last.intern
       parent_name = parent.is_a?(String) ?
                         parent : parent.name

       rparent = Cosmos::Registry.instance.find_entity(:type => parent_type, :name => parent_name)
       raise Omega::DataNotFound, "parent entity of type #{parent_type} with name #{parent_name} not found" if rparent.nil?

       rparent.add_child entity

       unless entity.location.nil?
         # entity.location.entity = entity
         Motel::Runner.instance.run entity.location
       end

       entity
    }

    rjr_dispatcher.add_handler('get_entity'){ |*args|
       type = args[0]
       name = args.length > 0 ? args[1] : nil

       entity = Cosmos::Registry.instance.find_entity(:type => type.intern, :name => name)

       raise Omega::DataNotFound, "entity of type #{type}" + (name.nil? ? "" : " with name #{name}") + " not found" if entity.nil?
       Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "cosmos_entity-#{entity.id}"},
                                                  {:privilege => 'view', :entity => 'cosmos_entities'}],
                                         :session => @headers['session_id'])

       entity
    }
  end
end # class RJRAdapter

end # module Cosmos
