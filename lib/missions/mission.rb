# Missions Mission definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/sproc'

# TODO catch errors in callbacks ?

require 'time'

module Missions

# Set of objectives created by a user (usually a npc) and
# assigned to another for completion.
#
# Incorprates callbacks to determine if user is eligable to accept mission,
# if/when mission is completed, and to run handlers at various points during
# the mission cycle.
class Mission
  # Unique string id of the mission
  attr_accessor :id

  # Title of the mission
  attr_accessor :title

  # Description of the mission
  attr_accessor :description

  # TODO some sort of intro sequence / text tie in?
  #   (also assignment and victory content)

  # Generic key/value store for data in the mission context,
  # for use by the various callbacks
  attr_accessor :mission_data

  # Id of user who created the mission
  attr_accessor :creator_id

  # Handle to Users::User who created the mission
  attr_reader :creator

  # Creator writer (also sets creator_id)
  def creator=(v)
    @creator = v
    @creator_id = v.id
  end

  # Array of mission assignment requirements
  attr_accessor :requirements

  # Return boolean indicating if user meets requirements
  # to be assigned to this mission
  def assignable_to?(user)
    !@assigned_to_id &&
    @requirements.all? { |req|
      # TODO catch exceptions (return false if any?)
      req.call self, user
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

# FIXME removed get user and add priv to user role:

  # Assign mission to the specified user
  def assign_to(user)
    return unless self.assignable_to?(user)
    @assigned_to    = user
    @assigned_to_id = user.id

    @assigned_time = Time.now
    @assignment_callbacks.each { |acb|
      acb.call self
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
  attr_accessor :victorious

  # Boolean indicating if user was failed mission
  attr_accessor :failed

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
      vc.call self
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
      vcb.call self
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
      fcb.call self
    }
  end

  # Mission initializer
  #
  # @param [Hash] args hash of options to initialize mission with
  # @option args [String] :id,'id' id to assign to the mission
  # @option args [String] :title,'title' title of the mission
  # @option args [String] :description,'description' description of the mission
  # @option args [String] :creator_id,'creator_id' id of user that created the mission
  # @option args [String] :assigned_to_id,'assigned_to_id' id of user that the mission is assigned to
  # @option args [Time]   :assigned_time,'assigned_time' time the mission was assigned to user
  # @option args [Integer] :timeout,'timeout' seconds which mission assignment is valid for
  # @option args [Array<String,Callables>] :requirements,'requirements' requirements which to validate upon assigning mission
  # @option args [Array<String,Callables>] :assignment_callbacks,'assignment_callbacks' callbacks which to invoke upon assigning mission
  # @option args [Array<String,Callables>] :victory_conditions,'victory_conditions' conditions which to determine if mission is completed
  # @option args [Array<String,Callables>] :victory_callbacks,'victory_callbacks' callbacks which to invoke upon successful mission completion
  # @option args [Array<String,Callables>] :failure_callbacks,'failure_callbacks' callbacks which to invoke upon mission failure
  # @option args [Missions::Mission] :mission, 'mission' mission to copy attributes from
  def initialize(args = {})
    attr_from_args args,
      :id                   => nil,
      :title                =>  "",
      :description          =>  "",
      :mission_data         =>  {},
      :creator_id      => nil,
      :assigned_to_id       => nil,
      :assigned_time        => nil,
      :timeout              => nil,
      :requirements         =>  [],
      :assignment_callbacks =>  [],
      :victory_conditions   =>  [],
      :victory_callbacks    =>  [],
      :failure_callbacks    =>  [],
      :victorious           => false,
      :failed               => false
    
    @assigned_time = Time.parse(@assigned_time) if @assigned_time.is_a?(String)

    [:@requirements, :@assignment_callbacks, :@victory_conditions,
     :@victory_callbacks, :@failure_callbacks].each { |c|
       i = self.instance_variable_get(c)
       unless i.is_a?(Array)
         i = [i]
         self.instance_variable_set(c, i)
       end

       i.each_index { |cbi|
         i[cqi] = SProc.new(&i[cqi]) if i[cqi].is_a?(Proc)
       }
     }
  end

  # Update the mission from the specified args
  #
  # @see initialize above for valid options accepted by update
  def update(args = {})
    attrs = [:id, :title, :description, :mission_data,
             :creator_id, :assigned_to_id, :assigned_time,
             :timeout, :requirements, :assgigmnent_callbacks,
             :victory_conditions, :failure_callbacks, :victorious,
             :failed]

    [:mission, 'mission'].each { |mission|
      update_from(args[mission], attrs) if args[mission]
    }

    update_from(args, attrs)
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
                       :creator_id => creator_id,
                       :assigned_to_id => assigned_to_id,
                       :timeout => timeout,
                       :assigned_time => assigned_time,
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
