# Omega Server Command definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'time'

module Omega
module Server

# Omega Command, tracks and invokes commands and hooks on various conditions.
#
# Should be subclassed to perform actual command and hook operations
class Command
  # Id of the event
  attr_accessor :id

  # Optional rate at which the command should be executed
  attr_accessor :exec_rate

  # Hooks to be invoked during various stages of the command
  attr_accessor :hooks

  # Special flag, indicates if 'first' hooks was called
  attr_accessor :ran_first_hooks

  # Time command was added to the registry
  attr_accessor :added_at

  # Time of last time command was run
  attr_accessor :last_ran_at

  # Registry which command is running in
  attr_accessor :registry

  # Node which to use to perform additional queries
  attr_accessor :node

  # Return bool indicating if command processes the specified entity.
  # By default returns false but may be overridden by specific commands
  # in other subsystems
  def processes?(entity)
    false
  end

  # Omega::Server::Command initializer
  #
  # @param [Hash] args hash of options to initialize event with
  # @option args [Symbol] id id of the command
  # @option args [Integer] exec_rate optional rate at which command should be executed
  # @option args [Hash<String, Array<Callable>>] hooks hooks to register w/ the command
  def initialize(args = {})
    attr_from_args args, :id              => nil,
                         :exec_rate       => nil,
                         :added_at        => Time.now.to_s, # XXX .to_s needed so time comparisons are acurate
                         :last_ran_at     => nil,
                         :ran_first_hooks => false,
                         :hooks =>  {:first  => [proc { self.first_hook  }],
                                     :before => [proc { self.before_hook }],
                                     :after  => [proc { self.after_hook  }],
                                     :last   => [proc { self.last_hook   }]}

    @added_at    = Time.parse(@added_at)    if @added_at.is_a?(String)
    @last_ran_at = Time.parse(@last_ran_at) if @last_ran_at.is_a?(String)
    #\@id = \@id.intern if \@id.is_a?(String)
  end

  # TODO this needed?
  def update(cmd)
    update_from(cmd, :ran_first_hooks, :added_at, :last_ran_at, :exec_rate)
  end

  # 'first' hook definition
  def first_hook
  end

  # 'before' hook definition
  def before_hook
  end

  # 'after' hook definition
  def after_hook
  end

  # 'last' hook definition
  def last_hook
  end

  # Run hooks of the specified type
  def run_hooks(hook)
    @ran_first_hooks = true if hook == :first

    @hooks[hook].each { |h|
      instance_exec &h
    } if @hooks[hook]
  end

  # Return boolean indicating if command should be run
  def should_run?
    (@last_ran_at.nil? || @exec_rate.nil? ||
     ((Time.now - @last_ran_at) > 1 / @exec_rate))
  end

  # Actually run command
  def run!
    @last_ran_at = Time.now
  end

  # Return bool indicating if cmd should be removed
  def remove?
    false
  end

  # Convert command to human readable string and return it
  def to_s
    "command-#{@id}"
  end

  def cmd_json
    {:id              => id,
     :exec_rate       => exec_rate,
     :ran_first_hooks => ran_first_hooks,
     :added_at        => added_at,
     :last_ran_at     => last_ran_at}
   end

   # Convert command to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       => cmd_json
     }.to_json(*a)
   end

   # Create new command from json representation
   def self.json_create(o)
     cmd = new(o['data'])
     return cmd
   end
end # class Command

# Convencience methods which commands may include to simplify operations
module CommandHelpers
  # update entity in registry
  def update_registry(entity)
    registry.update(entity) { |e| e.respond_to?(:id) && e.id == entity.id }
  end

  # retrieve entity from registry
  def retrieve(entity_id)
    registry.entity { |e| e.respond_to?(:id) && e.id == entity_id }
  end

  # run callbacks with args on the registry entity
  def run_callbacks(entity, *args)
    registry.safe_exec { |entities|
      e = entities.find { |e| e.respond_to?(:id) && e.id == entity.id }
      e.run_callbacks *args
    }
  end

  # invoke a command via the node
  def invoke(*args)
    node.invoke *args
  end
end

end # module Server
end # module Omega
