# Stats rjr adapter
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/exceptions'
require 'rjr/dispatcher'

module Stats

# Provides mechanisms to invoke Stats subsystem functionality remotely over RJR.
#
# Do not instantiate as interface is defined on the class.
class RJRAdapter
  class << self
    # @!group Config options

    # User to use to communicate w/ other modules over the local rjr node
    attr_accessor :stats_rjr_username

    # Password to use to communicate w/ other modules over the local rjr node
    attr_accessor :stats_rjr_password

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.stats_rjr_username  = config.stats_rjr_user
      self.stats_rjr_password  = config.stats_rjr_pass
    end
  end

  # Return user which can invoke privileged stats operations over rjr
  #
  # First instantiates user if it doesn't exist.
  def self.user
    @@stats_user ||= Users::User.new(:id       => Stats::RJRAdapter.stats_rjr_username,
                                     :password => Stats::RJRAdapter.stats_rjr_password)
  end


  # Initialize the Stats subsystem and rjr adapter.
  def self.init
    Stats::Registry.instance.init
    self.register_handlers(RJR::Dispatcher)
    @@local_node = RJR::LocalNode.new :node_id => 'manufactured'
    @@local_node.message_headers['source_node'] = 'manufactured'
    @@local_node.invoke_request('users::create_entity', self.user)
    role_id = "user_role_#{self.user.id}"
    @@local_node.invoke_request('users::add_privilege', role_id, 'view',   'manufactured_entities')
    @@local_node.invoke_request('users::add_privilege', role_id, 'view',   'cosmos_entities')
    @@local_node.invoke_request('users::add_privilege', role_id, 'view',   'users_entities')
    @@local_node.invoke_request('users::add_privilege', role_id, 'view',   'missions')

    session = @@local_node.invoke_request('users::login', self.user)
    @@local_node.message_headers['session_id'] = session.id
    Stats::Registry.instance.node = @@local_node
  end

  # Register handlers with the RJR::Dispatcher to invoke various stats operations
  #
  # @param rjr_dispatcher dispatcher to register handlers with
  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('stats::get') { |*args|
      # TODO support non-id filters
      stat_id = args.shift

      # TODO permissions on particular stats? (perhaps stats themselves can specify if they require more restricted access?)
      Users::Registry.require_privilege(:privilege => 'view', :entity => "stats",
                                        :session => @headers['session_id'])

      stat = Stats::Registry.instance.get(stat_id)
      raise Omega::DataNotFound, "stat specified by #{stat_id} not found" if stat.nil?
      stat.generate *args
    }
  end
end

end
