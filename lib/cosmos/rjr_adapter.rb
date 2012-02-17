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
       RJR::Logger.info "received create entity #{entity} under #{parent} request"
       begin
         parent_type = parent.is_a?(String) ?
                           parent.intern :
                           parent.class.to_s.downcase.underscore.split('/').last.intern
         parent_name = parent.is_a?(String) ?
                           parent : parent.name

         rparent = Cosmos::Registry.instance.find_entity(:type => parent_type, :name => parent_name)
         # TODO raise exception if rparent.nil?

         rparent.add_child entity

         Motel::Runner.instance.run entity.location unless entity.location.nil?

       rescue Exception => e
         RJR::Logger.warn "request create entity #{entity} failed with exception #{e}"
       end
       RJR::Logger.info "request create entity returning #{entity}"
       entity
    }

    rjr_dispatcher.add_handler('get_entity'){ |type, name|
       if name.nil?
         RJR::Logger.info "received get entity #{type} request"
       else
         RJR::Logger.info "received get entity #{type} with name #{name} request"
       end
       entity = nil
       begin
         entity = Cosmos::Registry.instance.find_entity(:type => type.intern, :name => name)
       rescue Exception => e
         RJR::Logger.warn "request get entity #{type} with name #{name} failed with exception #{e}"
       end
       RJR::Logger.info "request get entity returning #{entity}"
       entity
    }
  end
end # class RJRAdapter

end # module Cosmos
