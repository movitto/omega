# Users rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'curb'
require 'active_support/inflector'

module Users

# Provides mechanisms to invoke Users subsystem functionality remotely over RJR.
#
# Do not instantiate as interface is defined on the class.
class RJRAdapter
  class << self
    # @!group Config options

    # Boolean toggling if recaptchas are enabled / required for user registration
    # @!scope class
    attr_accessor :recaptcha_enabled

    # String recaptch public key
    # @!scope class
    attr_accessor :recaptcha_pub_key

    # String recaptch private key
    # @!scope class
    attr_accessor :recaptcha_priv_key

    # Boolean indicating if mediawiki account should be created
    #   on new user creation. Requires external mediawiki adapter script
    # @!scope class
    attr_accessor :mediawiki_enabled

    # String directory of mediawiki installation
    # @!scope class
    attr_accessor :mediawiki_dir

    # String URL of the omega server
    # @!scope class
    attr_accessor :omega_url

    # Array<String> Usernames to mark as permenant on creation
    attr_accessor :permenant_users

    # User to use to communicate w/ other modules over the local rjr node
    attr_accessor :users_rjr_username

    # Password to use to communicate w/ other modules over the local rjr node
    attr_accessor :users_rjr_password

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.recaptcha_enabled  = config.recaptcha_enabled
      self.recaptcha_pub_key  = config.recaptcha_pub_key
      self.recaptcha_priv_key = config.recaptcha_priv_key
      self.mediawiki_enabled  = config.mediawiki_enabled
      self.mediawiki_dir      = config.mediawiki_dir
      self.omega_url          = config.omega_url
      self.permenant_users    = config.permenant_users
      self.users_rjr_username = config.users_rjr_user
      self.users_rjr_password = config.users_rjr_pass
    end

    # @!endgroup
  end

  # Return user which can invoke privileged users operations over rjr
  #
  # First instantiates user if it doesn't exist.
  def self.user
    @@users_user ||= Users::User.new(:id       => Users::RJRAdapter.users_rjr_username,
                                     :password => Users::RJRAdapter.users_rjr_password)
  end

  # Initialize the Users subsystem and rjr adapter.
  def self.init
    self.permenant_users = [] if self.permenant_users.nil?

    Users::ChatProxy.clear
    Users::Registry.instance.init
    self.register_handlers(RJR::Dispatcher)
    @@local_node = RJR::LocalNode.new :node_id => 'users'
    @@local_node.message_headers['source_node'] = 'users'
    @@local_node.invoke_request('users::create_entity', self.user)

    session = @@local_node.invoke_request('users::login', self.user)
    @@local_node.message_headers['session_id'] = session.id
  end

  # Register handlers with the RJR::Dispatcher to invoke various users operations
  #
  # @param rjr_dispatcher dispatcher to register handlers with
  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('users::create_entity'){ |entity|
       unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
         Users::Registry.require_privilege(:privilege => 'create', :entity => 'users_entities',
                                           :session   => @headers['session_id'])
       end

       raise ArgumentError, "entity must be one of #{Users::Registry::VALID_TYPES}" unless Users::Registry::VALID_TYPES.include?(entity.class)
       raise ArgumentError, "entity id #{entity.id} already taken" unless Users::Registry.instance.find(:type => entity.class.to_s, :id => entity.id).empty?

       entity.secure_password = true if entity.is_a? Users::User

       Users::Registry.instance.create entity

       if entity.is_a?(Users::User) || entity.is_a?(Users::Alliance)
         owner = nil

         if entity.is_a?(Users::User)
           owner = entity

           # create new user role for user
           role = Users::Role.new :id => "user_role_#{entity.id}"
           @@local_node.invoke_request('users::create_entity', role)
           @@local_node.invoke_request('users::add_role', entity.id, role.id)

           # mark permenant users as such
           if Users::RJRAdapter.permenant_users.find { |un| entity.id == un }
             entity.permenant = true
           end

         else
           owner = entity.members.first
         end

         # add permissions to view & modify entity to owner
         unless owner.nil?
           role_id = "user_role_#{owner.id}"
           @@local_node.invoke_request('users::add_privilege', role_id, 'view',   "users_entity-#{entity.id}")
           @@local_node.invoke_request('users::add_privilege', role_id, 'view',   "user-#{entity.id}")
           @@local_node.invoke_request('users::add_privilege', role_id, 'modify', "users_entity-#{entity.id}")
           @@local_node.invoke_request('users::add_privilege', role_id, 'modify', "user-#{entity.id}")
         end
       end

       entity
    }

    rjr_dispatcher.add_handler(['users::get_entity', 'users::get_entities']){ |*args|
       filter = {}
       while qualifier = args.shift
         raise ArgumentError, "invalid qualifier #{qualifier}" unless ["of_type", "with_id"].include?(qualifier)
         val = args.shift
         raise ArgumentError, "qualifier #{qualifier} requires value" if val.nil?
         qualifier = case qualifier
                       when "of_type"
                         :type
                       when "with_id"
                         :id
                     end
         filter[qualifier] = val
       end

       return_first = filter.has_key?(:id)

       entities = Users::Registry.instance.find(filter)

       if return_first
         entities = entities.first
         raise Omega::DataNotFound, "users entity specified by #{filter.inspect} not found" if entities.nil?
         Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "users_entity-#{entities.id}"},
                                                    {:privilege => 'view', :entity => 'users_entities'}],
                                           :session   => @headers['session_id'])

       else
         entities.reject! { |entity|
           !Users::Registry.check_privilege(:any => [{:privilege => 'view', :entity => "users_entity-#{entity.id}"},
                                                     {:privilege => 'view', :entity => 'users_entities'}],
                                            :session => @headers['session_id'])
         }
       end

       entities
    }

    rjr_dispatcher.add_handler('users::send_message') { |message|
      raise ArgumentError, "message must be a string of non-zero length" unless message.is_a?(String) && message != ""

      user = Users::Registry.instance.current_user :session => @headers['session_id']

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "user-#{user.id}"},
                                                 {:privilege => 'modify', :entity => 'users'}],
                                        :session   => @headers['session_id'])

       Users::ChatProxy.proxy_for(user.id).proxy_message message
       nil
    }

    rjr_dispatcher.add_handler('users::subscribe_to_messages') {
       user = Users::Registry.instance.current_user :session => @headers['session_id']

       # TODO ensure that rjr_node_type supports persistant connections

       Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "user-#{user.id}"},
                                                  {:privilege => 'view', :entity => "users_entity-#{user.id}"},
                                                  {:privilege => 'view', :entity => 'users_entities'}],
                                         :session => @headers['session_id'])

       callback = Users::ChatCallback.new { |message|
         begin
           @rjr_callback.invoke('users::on_message', message)
         rescue RJR::Errors::ConnectionError => e
           RJR::Logger.warn "subscribe_to_messages #{user.id} client disconnected"
           # Users::ChatProxy.proxy_for(user.id).remove_callback # TODO
         end
       }

       #@rjr_node.on(:closed) { |node|
       # Users::ChatProxy.proxy_for(user.id).remove_callback # TODO
       #}

       Users::ChatProxy.proxy_for(user.id).connect.add_callback callback
       nil
    }

    rjr_dispatcher.add_handler('users::get_messages') {
      user = Users::Registry.instance.current_user :session => @headers['session_id']

      Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "user-#{user.id}"},
                                                 {:privilege => 'view', :entity => "users_entity-#{user.id}"},
                                                 {:privilege => 'view', :entity => 'users_entities'}],
                                        :session => @headers['session_id'])

      Users::ChatProxy.proxy_for(user.id).messages
    }

     rjr_dispatcher.add_handler('users::login') { |user|
       raise ArgumentError, "user must be an instance of Users::User" unless user.is_a?(Users::User)
       session = nil
       user_entity = Users::Registry.instance.find(:id => user.id).first
       raise Omega::DataNotFound, "user specified by id #{user.id} not found" if user_entity.nil?
       if user_entity.valid_login?(user.id, user.password)
         # TODO store the rjr node which this user session was established on for use in other handlers
         session = Users::Registry.instance.create_session(user_entity)
       else
         raise ArgumentError, "invalid user"
       end

       # FIXME log the user into mediawiki, return session id for them to use, disable explicit mediawiki login / account creation

       session
     }

     rjr_dispatcher.add_handler('users::logout') { |session_id|
       user = Users::Registry.instance.find(:session_id => session_id).first
       raise Omega::DataNotFound, "user specified by session_id #{session_id} not found" if user.nil?
       Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "user-#{user.id}"},
                                                  {:privilege => 'modify', :entity => 'users'}],
                                         :session   => @headers['session_id'])

       Users::Registry.instance.destroy_session(:session_id => session_id)
       nil
     }

     rjr_dispatcher.add_handler('users::add_role') { |user_id, role_id|
       unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
         Users::Registry.require_privilege(:privilege => 'modify', :entity => 'users_entities',
                                           :session   => @headers['session_id'])
       end

       user = Users::Registry.instance.find(:id => user_id, :type => "Users::User").first
       role = Users::Registry.instance.find(:id => role_id, :type => "Users::Role").first
       raise Omega::DataNotFound, "user specified by id #{user_id} not found" if user.nil?
       raise Omega::DataNotFound, "role specified by id #{role_id} not found" if role.nil?
       Users::Registry.instance.safely_run {
         user.add_role role
       }
       nil
     }

     # rjr_dispatcher.add_handler('users::remove_role') { |*args| # TODO

     rjr_dispatcher.add_handler('users::add_privilege') { |*args|
       unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
         Users::Registry.require_privilege(:privilege => 'modify', :entity => 'users_entities',
                                           :session   => @headers['session_id'])
       end

       role_id      = args[0]
       privilege_id = args[1]
       entity_id    = args.size > 2 ? args[2] : nil

       role = Users::Registry.instance.find(:id => role_id, :type => "Users::Role").first
       raise Omega::DataNotFound, "role specified by id #{role_id} not found" if role.nil?
       Users::Registry.instance.safely_run {
         role.add_privilege privilege_id, entity_id
       }
       nil
     }

     # rjr_dispatcher.add_handler('users::remove_privilege') { |*args| # TODO

     rjr_dispatcher.add_handler("users::register") { |user|
       raise ArgumentError, "user must be an instance of Users::User" unless user.is_a?(Users::User)

       # validate email format, user isn't already taken
       raise ArgumentError, "invalid user email"    unless user.valid_email?
       raise ArgumentError, "user id already taken" unless Users::Registry.instance.find(:id => user.id).empty?
       raise ArgumentError, "valid username and password is required"  unless user.id.is_a?(String) && user.password.is_a?(String) && user.id != "" && user.password != ""

       if Users::RJRAdapter.recaptcha_enabled
         # TODO ensure node type isn't amqp so that client_ip is available ?
         # ensure recaptcha is valid
         recaptcha_response = Curl::Easy.http_post 'http://www.google.com/recaptcha/api/verify',
                                             Curl::PostField.content('privatekey', Users::RJRAdapter.recaptcha_priv_key),
                                             Curl::PostField.content('remoteip', @client_ip),
                                             Curl::PostField.content('challenge', user.recaptcha_challenge),
                                             Curl::PostField.content('response', user.recaptcha_response)
         recaptcha_response = recaptcha_response.body_str.split.first
         raise ArgumentError, "invalid recaptcha" if recaptcha_response != "true"
       end

       # generate random registraton code
       user.registration_code = Users::User.random_registration_code

       # clear alliances
       user.alliances = []

       # create new user
       secure_user = @@local_node.invoke_request('users::create_entity', user)


       # send users::confirm_register link via email
       message = <<MESSAGE_END
From: #{EmailHelper.smtp_from_address}
To: #{user.email}
Subject: New Omega Account

This is to inform you that your new omega account has been created. You
will need to activate your registration code by navigating to the following
link:

  #{Users::RJRAdapter.omega_url}confirm.html?rc=#{user.registration_code}

MESSAGE_END
       EmailHelper.instance.send_email user.email, message
       # TODO if email is disabled just autoregister ?

       secure_user
     }

     rjr_dispatcher.add_handler("users::confirm_register") { |registration_code|
       user = Users::Registry.instance.find(:registration_code => registration_code).first
       raise Omega::DataNotFound, "user specified by registration code #{registration_code} not found" if user.nil?

       Users::Registry.instance.safely_run {
         user.registration_code = nil
       }

       # issue request to create mediawiki user
       # we just use a custom script leveraging the mw api to do this for now
       if Users::RJRAdapter.mediawiki_enabled
         # TODO use original / unencrypted pass or different pass ?
         system("cd #{Users::RJRAdapter.mediawiki_dir} && ./create_user.php #{user.id} #{user.password} #{user.email}")
       end

       nil
     }

     rjr_dispatcher.add_handler("users::update_user") { |user|
       raise ArgumentError, "user must be an instance of Users::User" unless user.is_a?(Users::User)

       user_entity = Users::Registry.instance.find(:id => user.id).first
       raise Omega::DataNotFound, "user specified by id #{user.id} not found" if user_entity.nil?
       Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "user-#{user.id}"},
                                                  {:privilege => 'modify', :entity => 'users'}],
                                         :session   => @headers['session_id'])
       Users::Registry.instance.safely_run {
         user_entity.update!(user)
       }
       user_entity
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
