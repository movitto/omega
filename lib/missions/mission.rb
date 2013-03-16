# Missions Mission definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO catch errors in callbacks ?

require 'time'

module Missions

# Represents a set of objectives created by a user (usually a npc) and
# assigned to another for completion. Incorprates callbacks to determine
# if user is eligable to accept mission and determine if/when mission is
# completed (or timeout expires). Also incorporates callbacks to run handlers
# at various points during the mission cycle.
class Mission
  # Node to use to query other subsystems
  attr_accessor :node

  # Unique string id of the mission
  attr_accessor :id

  # Title of the mission
  attr_accessor :title

  # Description of the mission
  attr_accessor :description

  # TODO some sort of intro sequence / text tie in? (also assignment and victory content)

  # Generic key/value store for data in the mission context,
  # for use by the various callbacks
  attr_accessor :mission_data

  # Id of user who created the mission
  attr_accessor :creator_user_id

  # Handle to Users::User who created the mission
  attr_accessor :creator_user
  alias :creator :creator_user

  # Array of mission assignment requirements
  attr_accessor :requirements

  # Return boolean indicating if user meets requirements
  # to be assigned to this mission
  def assignable_to?(user)
    !@assigned_to_id &&
    @requirements.all? { |req|
      # TODO catch exceptions (return false if any?)
      req.call self, user, @node
    }
  end

  # Id of user who is assigned to the mission
  attr_accessor :assigned_to_id

  # Return boolean indicating if mission is assigned
  # to the the specified user
  def assigned_to?(user)
    if user.is_a?(Users::User)
      return @assigned_to_id == user.id
    end

    return @assigned_to_id == user
  end

  # Handle to Users::User who is assigned to the mission
  attr_accessor :assigned_to

  # Array of callbacks which to invoke on assignment
  attr_accessor :assignment_callbacks

  # Assign mission to the specified user
  def assign_to(user)
    return unless self.assignable_to?(user)
    if user.is_a?(String)
      # XXX don't like reaching into registry here (and probably don't need to)
      @assigned_to_id = user
      @assigned_to    = @node.invoke_request('users::get_entity', 'with_id', user) unless @node.nil?

    else
      @assigned_to    = user
      @assigned_to_id = user.id

    end

    @assigned_time = Time.now

    # use node to create new view-mission-id permission
    unless @node.nil?
      begin
        @node.invoke_request('users::add_privilege', "user_role_#{user.id}", 'view', "mission-#{self.id}")
      rescue Exception => e
      end
    end

    @assignment_callbacks.each { |acb|
      acb.call self, @node
    }
  end

  # Time mission was assigned to user
  attr_accessor :assigned_time

  # Time user has to complete mission
  attr_accessor :timeout

  # Returns boolean indicating if time to complete
  # mission has expired
  def expired?
    @assigned_time && ((@assigned_time + @timeout) < Time.now)
  end

  # Clear mission assignment
  def clear_assignment!
    @assigned_to    = nil
    @assigned_to_id = nil
    @assigned_time  = nil
  end

  # Boolean indicating if user was victorious in mission
  attr_reader :victorious

  # Boolean indicating if user was failed mission
  attr_reader :failed

  # Retuns boolean indicating if mission is active, eg
  # assigned, not expired and not victorious / failed
  def active?
    !self.assigned_time.nil? && !self.expired? && !self.victorious && !self.failed
  end

  # Array of mission victory conditions
  attr_accessor :victory_conditions

  # Returns boolean indicating if mission was completed
  # or not
  def completed?
    @victory_conditions.all? { |vc|
      vc.call self, @node
    }
  end

  # Array of callbacks which to invoke on victory
  attr_accessor :victory_callbacks

  # Set mission victory to true
  def victory!
    raise RuntimeError, "must be assigned"         if @assigned_to_id.nil?
    raise RuntimeError, "cannot already be failed" if @failed
    @victorious = true
    @failed     = false

    @victory_callbacks.each { |vcb|
      vcb.call self, @node
    }
  end

  # Array of callbacks which to invoke on failure
  attr_accessor :failure_callbacks

  # Set mission failure to true
  def failed!
    raise RuntimeError, "must be assigned"             if @assigned_to_id.nil?
    raise RuntimeError, "cannot already be victorious" if @victorious
    @victorious = false
    @failed     = true

    @failure_callbacks.each { |fcb|
      fcb.call self, @node
    }
  end

  # Mission initializer
  # @param [Hash] args hash of options to initialize mission with
  # @see update below for valid options accepted by initialize
  def initialize(args = {})
    @node                 = nil
    @id                   = ""
    @title                = ""
    @description          = ""
    @mission_data         = {}
    @creator_user_id      = nil
    @assigned_to_id       = nil
    @assigned_time        = nil
    @timeout              = nil
    @requirements         = []
    @assignment_callbacks = []
    @victory_conditions   = []
    @victory_callbacks    = []
    @failure_callbacks    = []
    @victorious           = false
    @failed               = false
    update(args)

    if @assigned_time.is_a?(String)
      @assigned_time = Time.parse(@assigned_time)
    end

    @requirements         = [@requirements]         unless @requirements.is_a?(Array)
    @assignment_callbacks = [@assignment_callbacks] unless @assignment_callbacks.is_a?(Array)
    @victory_conditions   = [@victory_conditions]   unless @victory_conditions.is_a?(Array)
    @victory_callbacks    = [@victory_callbacks]    unless @victory_callbacks.is_a?(Array)
    @failure_callbacks    = [@failure_callbacks]    unless @failure_callbacks.is_a?(Array)

    [@requirements, @assignment_callbacks,
     @victory_conditions, @victory_callbacks,
     @failure_callbacks].each { |callable_q|
      callable_q.each_index { |cqi|
        callable_q[cqi] = SProc.new(&callable_q[cqi]) if callable_q[cqi].is_a?(Proc)
      }
    }
  end

  # Update the mission from the specified args
  # @param [Hash] args hash of options to update mission with
  # @option args [RJR::Node] :node,'node' node to assign to mission to use for queries
  # @option args [String] :id,'id' id to assign to the mission
  # @option args [String] :title,'title' title of the mission
  # @option args [String] :description,'description' description of the mission
  # @option args [String] :creator_user_id,'creator_user_id' id of user that created the mission
  # @option args [String] :assigned_to_id,'assigned_to_id' id of user that the mission is assigned to
  # @option args [Time]   :assigned_time,'assigned_time' time the mission was assigned to user
  # @option args [Integer] :timeout,'timeout' seconds which mission assignment is valid for
  # @option args [Array<String,Callables>] :requirements,'requirements' requirements which to validate upon assigning mission
  # @option args [Array<String,Callables>] :assignment_callbacks,'assignment_callbacks' callbacks which to invoke upon assigning mission
  # @option args [Array<String,Callables>] :victory_conditions,'victory_conditions' conditions which to determine if mission is completed
  # @option args [Array<String,Callables>] :victory_callbacks,'victory_callbacks' callbacks which to invoke upon successful mission completion
  # @option args [Array<String,Callables>] :failure_callbacks,'failure_callbacks' callbacks which to invoke upon mission failure
  # @option args [Missions::Mission] :mission, 'mission' mission to copy attributes from
  def update(args = {})
    @node                  =  args[:node]                 || args['node']                 || @node
    @id                    =  args[:id]                   || args['id']                   || @id
    @title                 =  args[:title]                || args['title']                || @title
    @description           =  args[:description]          || args['description']          || @description
    @mission_data          =  args[:mission_data]         || args['mission_data']         || @mission_data
    @creator_user_id       =  args[:creator_user_id]      || args['creator_user_id']      || @creator_user_id
    @assigned_to_id        =  args[:assigned_to_id]       || args['assigned_to_id']       || @assigned_to_id
    @assigned_time         =  args[:assigned_time]        || args['assigned_time']        || @assigned_time
    @timeout               =  args[:timeout]              || args['timeout']              || @timeout
    @requirements          =  args[:requirements]         || args['requirements']         || @requirements
    @assignment_callbacks  =  args[:assignment_callbacks] || args['assignment_callbacks'] || @assignment_callbacks
    @victory_conditions    =  args[:victory_conditions]   || args['victory_conditions']   || @victory_conditions
    @victory_callbacks     =  args[:victory_callbacks]    || args['victory_callbacks']    || @victory_callbacks
    @failure_callbacks     =  args[:failure_callbacks]    || args['failure_callbacks']    || @failure_callbacks
    @victorious            =  args[:victorious]           || args['victorious']           || @victorious
    @failed                =  args[:failed]               || args['failed']               || @failed

    [:mission, 'mission'].each { |mission|
      if args[mission]
        update(:id                   => args[mission].id,
               :title                => args[mission].title,
               :description          => args[mission].description,
               :creator_user_id      => args[mission].creator_user_id,
               :assigned_to_id       => args[mission].assigned_to_id,
               :assigned_time        => args[mission].assigned_time,
               :timeout              => args[mission].timeout,
               :requirements         => args[mission].requirements,
               :assignment_callbacks => args[mission].assignment_callbacks,
               :victory_conditions   => args[mission].victory_conditions,
               :victory_callbacks    => args[mission].victory_callbacks,
               :failure_callbacks    => args[mission].failure_callbacks,
               :victorious           => args[mission].victorious,
               :failed               => args[mission].failed)
      end
    }
  end

  # Return a copy of this mission, setting any additional attributes given
  def clone(args = {})
    m = Mission.new :mission => self
    m.update(args)
    m
  end

  # Convert mission to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id,
                       :title => title, :description => description,
                       :mission_data => mission_data,
                       :creator_user_id => creator_user_id, :assigned_to_id => assigned_to_id,
                       :timeout => timeout, :assigned_time => assigned_time,
                       :requirements         => requirements,
                       :assignment_callbacks => assignment_callbacks,
                       :victory_conditions   => victory_conditions,
                       :victory_callbacks    => victory_callbacks,
                       :failure_callbacks    => failure_callbacks,
                       :victorious => victorious, :failed => failed}
    }.to_json(*a)
  end

  # Convert mission to human readable string and return it
  def to_s
    "mission-#{@id}"
  end

  # Create new mission from json representation
  def self.json_create(o)
    mission = new(o['data'])
    return mission
  end

end

end
