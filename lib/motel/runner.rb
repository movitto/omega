# Defines the LocationRunner and Runner classes, core to the motel engine,
# and is responsible for managing locations and moving them according to
# their corresponding movement_strategies
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

module Motel

# A LocationRunner runs a Location by moving it via
# its associated MovementStrategy.
class LocationRunner
   attr_reader :location
   attr_reader :run_thread

   def initialize(location)
     return if location.nil? || location.id.nil? || location.class != Location

     @terminate = false
     @location  = location
     @location_lock = Mutex.new
     $logger.info " running location " + location.to_s

     # TODO at some point use a thread pool approach
     @run_thread = Thread.new { run_move_cycle(location) }
   end

   # Terminate run cycle, stopping location movement.
   # After this the runner cannot be used again
   def terminate
      @terminate = true
      @location_lock.synchronize{
        unless run_thread.nil?
          @run_thread.join
          @run_thread = nil
        end
      }
   end

 private

  # Launched in a seperate thread, run_move_cycle 
  # runs a location according to its associated 
  # movement strategy with a specified delay between
  # runs. Terminated when the Runner.terminate 
  # method is invoked
  def run_move_cycle(location)
     # track the time between runs
     start_time = Time.now 

     # run until we are instructed not to
     until(@terminate) do
        $logger.debug "runner invoking move on location " + location.to_s + " via " + location.movement_strategy.type.to_s + " movement strategy"

        ## perform the actual move
        location.movement_strategy.move location, start_time - Time.now
        start_time = Time.now 

        # TODO see if we've actually moved b4 invoking callbacks
        location.movement_strategy.movement_callbacks.each { |callback|
           callback.call(location)
        }

        ## delay as long as the strategy tells us to
        sleep location.movement_strategy.step_delay
     end
  end

end


# A Runner manages groups of LocationRunner instances
# Restricts use to a single instance, obtained via the
# 'get' method
class Runner

 private
  
  # Default class constructor
  # private as runner should be accessed through singleton 'get' method
  def initialize
     # set to true to terminate the runner
     @terminate = false

     # locations is a list of instances of LocationRunner to manage
     @location_runners    = []
     @runners_lock = Mutex.new
  end

 public

  # singleton getter
  def self.get
    @@singleton_instance = Runner.new if !defined? @@singleton_instance || @@singleton_instance.nil?
    return @@singleton_instance
  end

  attr_reader :location_runners

  # helper method, return all locations associated w/ runners
  def locations
     [] if @location_runners.nil? || @location_runners.size == 0
     @location_runners.collect { |runner| runner.location }
  end

  # clear all location_runners
  def clear
     @location_runners.clear
  end

  # Terminate all run cycles, stopping all location movements.
  # After this the runner cannot be used again
  def terminate
     @terminate = true
     @runners_lock.synchronize{
        @location_runners.each { |runner|
          runner.terminate
        }
     }
  end

  # Run a location using this runner. If the location
  # is already being run by this runner, do nothing.
  # A new thread will be launched to run the actual move cycle
  def run(location)
     @runners_lock.synchronize{
        unless @location_runners.find { |l| l.location.id == location.id}
          @location_runners.push LocationRunner.new(location)
        end
     }
  end

end

end # module motel
