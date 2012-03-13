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

    rjr_dispatcher.add_handler('users::send_message') { |user_id, message|
       RJR::Logger.info "received send_message #{message} from #{user_id} request"
       begin
         Users::ChatProxy.proxy_for(user_id).proxy_message message
       rescue Exception => e
         RJR::Logger.info "send_message #{message} from #{user_id} request failed with exception #{e}"
       end
       RJR::Logger.info "send_message #{message} from #{user_id} request returning"
       nil
     }

    rjr_dispatcher.add_handler('users::subscribe_to_messages') { |user_id|
       RJR::Logger.info "received subscribe_to_messages #{user_id} request"
       begin
         callback = Users::ChatCallback.new { |message|
           begin
             RJR::Logger.debug "subscribe_to_messages #{user_id} request sending #{message} to user"
             @rjr_callback.invoke(message)
           rescue RJR::Errors::ConnectionError => e
             RJR::Logger.warn "subscribe_to_messages #{user_id} client disconnected"
             # Users::ChatProxy.proxy_for(user_id).remove_callback # TODO
           end
         }
         Users::ChatProxy.proxy_for(user_id).add_callback callback
       rescue Exception => e
         RJR::Logger.info "subscribe_to_messages #{user_id} request failed with exception #{e}"
       end
       RJR::Logger.info "subscribe_to_messages #{user_id} request returning"
       nil
     }

     rjr_dispatcher.add_handler('users::login') { |user|
       RJR::Logger.info "received login as #{user.id} request"
       session = nil
       begin
         user_entity = Users::Registry.instance.find(:id => user.id).first
         if user_entity.valid_login?(user.id, user.password)
           session = Users::Registry.instance.create_session(user_entity)
         else
           # TODO throw exception
         end
       rescue Exception => e
         RJR::Logger.info "login as #{user.id} request failed with exception #{e}"
       end
       RJR::Logger.info "login as #{user.id} request returning #{session.to_json}"
       session
     }

     rjr_dispatcher.add_handler('users::logout') { |session_id|
       RJR::Logger.info "received logout #{session_id} request"
       begin
         Users::Registry.instance.destroy_session(session_id)
       rescue Exception => e
         RJR::Logger.info "logout #{session_id} request failed with exception #{e}"
       end
       RJR::Logger.info "logout #{session_id} request returning"
       nil
     }

  end

end # class RJRAdapter

end # module Users
