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

       entity = Users::Registry.instance.find(:id => id).first
       entity
    }

    rjr_dispatcher.add_handler('users::get_all_entities') { |*args|
       type = args.length > 0 ? args[0] : nil
       Users::Registry.require_privilege(:privilege => 'view', :entity => 'users_entities',
                                         :session   => @headers['session_id'])

       Users::Registry.instance.find :type => type
    }

    rjr_dispatcher.add_handler('users::send_message') { |user_id, message|
      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "user-#{user_id}"},
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
           @rjr_callback.invoke('users::on_message', message)
         rescue RJR::Errors::ConnectionError => e
           RJR::Logger.warn "subscribe_to_messages #{user_id} client disconnected"
           # Users::ChatProxy.proxy_for(user_id).remove_callback # FIXME
         end
       }
       Users::ChatProxy.proxy_for(user_id).add_callback callback
       nil
     }

     rjr_dispatcher.add_handler('users::login') { |user|
       session = nil
       user_entity = Users::Registry.instance.find(:id => user.id).first
       raise Omega::DataNotFound, "user specified by id #{user.id} not found" if user_entity.nil?
       if user_entity.valid_login?(user.id, user.password)
         session = Users::Registry.instance.create_session(user_entity)
       else
         raise ArgumentError, "invalid user"
       end
       session
     }

     rjr_dispatcher.add_handler('users::logout') { |session_id|
       user = Users::Registry.instance.find(:session_id => session_id).first
       Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "user-#{user.id}"},
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

     rjr_dispatcher.add_handler("users::register") { |user|
       # validate email format, user isn't already taken
       raise ArgumentError, "invalid user email"    unless user.valid_email?
       raise ArgumentError, "user id already taken" unless Users::Registry.instance.find(:id => user.id).empty?

       # generate random registraton code
       user.registration_code = Users::User.random_registration_code

       # create new user
       Users::Registry.instance.create user

       # TODO send users::confirm_register link via email
       user
     }

     rjr_dispatcher.add_handler("users::confirm_register") { |registration_code|
       user = Users::Registry.instance.find(:registration_code => registration_code).first
       raise Omega::DataNotFound, "user specified by registration code #{registration_code} not found" if user.nil?

       user.registration_code = nil

       # assign it base privileges

       # TODO issue request to create mediawiki user
       nil
     }

     rjr_dispatcher.add_handler("users::update_user") { |user|
       user_entity = Users::Registry.instance.find(:id => user.id).first
       raise Omega::DataNotFound, "user specified by id #{user.id} not found" if user_entity.nil?
       Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "user-#{user.id}"},
                                                  {:privilege => 'modify', :entity => 'users'}],
                                         :session   => @headers['session_id'])
       user_entity.update!(user)
       user
     }

    rjr_dispatcher.add_handler('users::save_state') { |output|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      output_file = File.open(output, 'a+')
      Users::Registry.instance.save_state(output_file)
      output_file.close
    }

    rjr_dispatcher.add_handler('users::restore_state') { |input|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      input_file = File.open(input, 'r')
      Users::Registry.instance.restore_state(input_file)
      input_file.close
    }

  end

end # class RJRAdapter

end # module Users
