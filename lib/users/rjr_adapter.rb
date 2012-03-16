# Users rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'active_support/inflector'

module Users

class RJRAdapter
  def self.init
    self.register_handlers(RJR::Dispatcher)
    #Users::Registry.instance.init
  end

  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('users::create_entity'){ |entity|
       unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
         Users::Registry.require_privilege(:privilege => 'create', :entity => 'users_entities',
                                           :session   => @headers['session_id'])
       end

       Users::Registry.instance.create entity
       entity
    }

    rjr_dispatcher.add_handler('users::get_entity'){ |id|
       Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "users_entity-#{id}"},
                                                  {:privilege => 'view', :entity => 'users_entities'}],
                                         :session => @headers['session_id'])

       Users::Registry.instance.find(:id => id).first
    }

    rjr_dispatcher.add_handler('users::get_all_entities') {
       Users::Registry.require_privilege(:privilege => 'view', :entity => 'users_entities',
                                         :session   => @headers['session_id'])

       Users::Registry.instance.find
    }

    rjr_dispatcher.add_handler('users::send_message') { |user_id, message|
      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "user-#{rloc.id}"},
                                                 {:privilege => 'modify', :entity => 'users'}],
                                        :session   => @headers['session_id'])

       Users::ChatProxy.proxy_for(user_id).proxy_message message
       nil
     }

    rjr_dispatcher.add_handler('users::subscribe_to_messages') { |user_id|
       Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "user-#{id}"},
                                                  {:privilege => 'view', :entity => "users_entity-#{id}"},
                                                  {:privilege => 'view', :entity => 'users_entities'}],
                                         :session => @headers['session_id'])

       callback = Users::ChatCallback.new { |message|
         begin
           @rjr_callback.invoke(message)
         rescue RJR::Errors::ConnectionError => e
           RJR::Logger.warn "subscribe_to_messages #{user_id} client disconnected"
           # Users::ChatProxy.proxy_for(user_id).remove_callback # TODO
         end
       }
       Users::ChatProxy.proxy_for(user_id).add_callback callback
       nil
     }

     rjr_dispatcher.add_handler('users::login') { |user|
       session = nil
       user_entity = Users::Registry.instance.find(:id => user.id).first
       if user_entity.valid_login?(user.id, user.password)
         session = Users::Registry.instance.create_session(user_entity)
       else
         # TODO throw exception
       end
       session
     }

     rjr_dispatcher.add_handler('users::logout') { |session_id|
       Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "user-#{rloc.id}"},
                                                  {:privilege => 'modify', :entity => 'users'}],
                                         :session   => @headers['session_id'])

       Users::Registry.instance.destroy_session(session_id)
       nil
     }

     rjr_dispatcher.add_handler('users::add_privilege') { |*args|
       unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
         Users::Registry.require_privilege(:privilege => 'modify', :entity => 'users_entities',
                                           :session   => @headers['session_id'])
       end

       user_id      = args[0]
       privilege_id = args[1]
       entity_id    = args.length > 2 ? args[2] : nil

       user = Users::Registry.instance.find(:id => user_id).first
       user.add_privilege Privilege.new(:id => privilege_id, :entity_id => entity_id)
       nil
     }

  end

end # class RJRAdapter

end # module Users
