# Users rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'active_support/inflector'

module Users

class RJRAdapter
  def self.init
    #Users::Registry.instance.init
  end

  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('users::create_entity'){ |entity|
       RJR::Logger.info "received create entity #{entity.to_json} request"
       begin
         Users::Registry.instance.create entity
       rescue Exception => e
         RJR::Logger.warn "request create entity #{entity} failed with exception #{e}"
       end
       RJR::Logger.info "request create entity returning #{entity}"
       entity
    }

    rjr_dispatcher.add_handler('users::get_entity'){ |id|
       RJR::Logger.info "received get entity #{id} request"
       entity = nil
       begin
         entity = Users::Registry.instance.find(:id => id).first
       rescue Exception => e
         RJR::Logger.warn "request get entity #{id} failed with exception #{e}"
       end
       RJR::Logger.info "request get entity #{id} returning #{entity}"
       entity
    }

    rjr_dispatcher.add_handler('users::get_all_entities') {
       RJR::Logger.info "received get all entities request"
       entities = []
       begin
         entities = Users::Registry.instance.find
       rescue Exception => e
         RJR::Logger.warn "get all entities failed w/ exception #{e}"
       end
       RJR::Logger.info "get all entities request returning #{entities}"
       entities
    }

  end

end # class RJRAdapter

end # module Users
