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
    # all in all missions is a pretty powerful role/user in terms
    #  of what it can do w/ the simulation
    @@local_node.invoke_request('users::add_privilege', role_id, 'view',     'users_entities')
    @@local_node.invoke_request('users::add_privilege', role_id, 'view',     'cosmos_entities')
    @@local_node.invoke_request('users::add_privilege', role_id, 'modify',   'cosmos_entities')
    @@local_node.invoke_request('users::add_privilege', role_id, 'view',     'manufactured_entities')
    @@local_node.invoke_request('users::add_privilege', role_id, 'create',   'manufactured_entities')
    @@local_node.invoke_request('users::add_privilege', role_id, 'modify',   'manufactured_entities')
    @@local_node.invoke_request('users::add_privilege', role_id, 'modify',   'manufactured_resources')
    @@local_node.invoke_request('users::add_privilege', role_id, 'create',   'missions')

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

      # set creator user,
      # could possibly go into missions model
      creator = mission.creator_user_id.nil? ?
        Users::Registry.current_user(:session => @headers['session_id']) :
        @@local_node.invoke_request('users::get_entity', 'with_id', mission.creator_user_id)
      mission.creator_user    = creator
      mission.creator_user_id = creator.id

      rmission = Missions::Registry.instance.create mission
      rmission.node = @@local_node
      rmission
    }

    rjr_dispatcher.add_handler(['missions::get_mission','missions::get_missions']){ |*args|
      return_first = false
      missions =
        Missions::Registry.instance.missions.select { |m|
           privs = [{:privilege => 'view', :entity => 'missions'},
                    {:privilege => 'view', :entity => "mission-#{m.id}"}]
           privs << {:privilege => 'view', :entity => 'unassigned_missions'} if m.assigned_to_id.nil?
           Users::Registry.check_privilege(:any => privs,
                                           :session   => @headers['session_id'])
        }

      while qualifier = args.shift
        raise ArgumentError, "invalid qualifier #{qualifier}" unless ["with_id", "assignable_to", "assigned_to", 'is_active'].include?(qualifier)
        val = args.shift
        raise ArgumentError, "qualifier #{qualifier} requires value" if val.nil?
        missions.select! { |m|
          case qualifier
          when "with_id"
            return_first = true
            m.id == val
          when "assignable_to"
            m.assignable_to?(val)
          when "assigned_to"
            return_first = true # relies on logic in assign_mission below restricting active mission assignment to one per user
            m.assigned_to?(val)
          when 'is_active'
            m.active? == val
          end
        }
      end

      return_first ? missions.first : missions
    }

    rjr_dispatcher.add_handler('missions::assign_mission'){ |mission_id,user_id|
      mission = Missions::Registry.instance.missions.find { |m| m.id == mission_id }
      user    =  @@local_node.invoke_request('users::get_entity', 'with_id', user_id)

      raise ArgumentError, "mission with id #{mission_id} could not be found" if mission.nil?
      raise ArgumentError, "user with id #{user_id} could not be found"       if user.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => 'users'},
                                                 {:privilege => 'modify', :entity => "user-#{user.id}"}],
                                        :session   => @headers['session_id'])

      # TODO modify missions here?
      #Users::Registry.require_privilege(:privilege => 'modify', :entity => 'missions',
      #                                  :session   => @headers['session_id'])

      user_missions = Missions::Registry.instance.missions.select { |m| m.assigned_to_id == user.id }
      active        = user_missions.select { |m| m.active? }

      # right now do not allow users to be assigned to more than one mission at a time
      # TODO incorporate MissionAgent attribute allowing user to accept > 1 mission at a time
      raise Omega::OperationError, "user #{user_id} already has an active mission" unless active.empty?

      # assign mission to user and return it
      Missions::Registry.instance.safely_run {
        # raise error if not assignable to user
        raise Omega::OperationError, "mission #{mission_id} not assignable to user" unless mission.assignable_to?(user)

        mission.assign_to user
      }

      mission
    }

    # TODO ?
    #rjr_dispatcher.add_handler('missions::unassign_mission'){ |mission_id|

    # callback to track manufactured events and generate corresponding mission system events
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
