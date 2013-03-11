# Missions rjr adapter
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Missions

# Provides mechanisms to invoke Missions subsystem functionality remotely over RJR.
#
# Do not instantiate as interface is defined on the class.
class RJRAdapter

  class << self
    # @!group Config options

    # User to use to communicate w/ other modules over the local rjr node
    attr_accessor :missions_rjr_username

    # Password to use to communicate w/ other modules over the local rjr node
    attr_accessor :missions_rjr_password

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.missions_rjr_username  = config.missions_rjr_user
      self.missions_rjr_password  = config.missions_rjr_pass
    end

    # @!endgroup
  end

  # Return user which can invoke privileged missions operations over rjr
  #
  # First instantiates user if it doesn't exist.
  def self.user
    @@missions_user ||= Users::User.new(:id       => Missions::RJRAdapter.missions_rjr_username,
                                        :password => Missions::RJRAdapter.missions_rjr_password)
  end


  # Initialize the Missions subsystem and rjr adapter.
  def self.init
    Missions::Registry.instance.init
    self.register_handlers(RJR::Dispatcher)

    @@local_node = RJR::LocalNode.new :node_id => 'missions'
    @@local_node.message_headers['source_node'] = 'missions'

    # Set shared node which events may use
    Missions::Event.node = @@local_node

    @@local_node.invoke_request('users::create_entity', self.user)
    role_id = "user_role_#{self.user.id}"
    # TODO add privileges needed by missions user
    #@@local_node.invoke_request('users::add_privilege', role_id, '',   '')

    session = @@local_node.invoke_request('users::login', self.user)
    @@local_node.message_headers['session_id'] = session.id
  end

  # Register handlers with the RJR::Dispatcher to invoke various mission operations
  #
  # @param rjr_dispatcher dispatcher to register handlers with
  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('missions::create_event'){ |event|
      Users::Registry.require_privilege(:privilege => 'create', :entity => 'mission_events',
                                        :session   => @headers['session_id'])

      raise ArgumentError, "Invalid #{event.class} event specified, must be Missions::Event subclass" unless event.kind_of?(Missions::Event)
      # TODO err if existing event w/ duplicate id ?

      revent = Missions::Registry.instance.create event
      revent
    }

    rjr_dispatcher.add_handler('missions::create_mission'){ |mission|
      # XXX be very careful who can do this as missions currently use SProcs
      # to evaluate arbitrary ruby code
      Users::Registry.require_privilege(:privilege => 'create', :entity => 'missions',
                                        :session   => @headers['session_id'])

      raise ArgumentError, "Invalid #{mission.class} mission specified, must be Missions::Mission subclass" unless mission.kind_of?(Missions::Mission)
      # TODO err if existing mission w/ duplicate id ?

      rmission = Missions::Registry.instance.create mission
      rmission.node = @@local_node
      rmission
    }

    #rjr_dispatcher.add_handler(['missions::get_mission','missions::get']){ |*args|
    #}

    #rjr_dispatcher.add_handler('missions::assign_mission'){ ||
    #}

    # callback to track manufactured events and generate corresponding
    # mission system events
    rjr_dispatcher.add_handler('manufactured::event_occurred'){ |*args|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE

      event = Missions::Events::Manufactured.new *args
      Missions::Registry.instance.create event
      nil
    }

    rjr_dispatcher.add_handler('missions::save_state') { |output|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      output_file = File.open(output, 'a+')
      Missions::Registry.instance.save_state(output_file)
      output_file.close
    }

    rjr_dispatcher.add_handler('missions::restore_state') { |input|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      input_file = File.open(input, 'r')
      Missions::Registry.instance.restore_state(input_file)
      input_file.close
    }
  end

end
end
