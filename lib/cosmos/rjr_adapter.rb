# Motel rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

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
                           parent.class.to_s.lower.underscore.intern,

         rparent = registry.find_entity(parent_type, parent.id)
         # TODO raise exception if rparent.nil?

         rparent.add_child entity

       rescue Exception => e
         RJR::Logger.warn "request create entity #{entity} failed with exception #{e}"
       end
       RJR::Logger.info "request create entity returning #{entity}"
       entity
    }
  end
end # class RJRAdapter

end # module Cosmos
