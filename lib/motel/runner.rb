# Defines the LocationRunner and Runner classes, core to the motel engine,
# and is responsible for managing locations and moving them according to
# their corresponding movement_strategies
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'singleton'
require 'motel/thread_pool'

module Motel

# Motel::Runner is a singleton class/object which acts as the primary
# mechanism to run locations in the system. It contains a thread pool
# which contains a specified number of threads which to move the managed
# locations in accordance to their location strategies.
class Runner
  include Singleton

  # locations being managed
  # TODO use ruby tree to store locations w/ heirarchy
  attr_accessor :locations

  # for testing purposes
  attr_reader :thread_pool, :terminate, :run_thread

  def initialize(args = {})
    @terminate = false
    @locations = []
    @locations_lock = Mutex.new

    @run_thread = nil
    @run_delay  = 2 # FIXME scale delay (only needed if locations is empty or has very few simple elements)
  end

  # Empty the list of locations being managed/tracked
  def clear
    @locations_lock.synchronize { 
      @locations.clear
    }
  end

  # add location to runner to be managed, after this is called, the location's 
  # movement strategy's move method will be invoked periodically
  def run(location)
    @locations_lock.synchronize { 
      Logger.debug "adding location #{location.id} to run queue"
      @locations.push location
    }
  end

  # Start moving the locations. If :async => true is passed in, this will immediately
  # return, else this will block until stop is called.
  def start(args = {})
    num_threads = 5
    num_threads = args[:num_threads] if args.has_key? :num_threads
    @terminate = false
    @thread_pool = ThreadPool.new(num_threads)

    if args.has_key?(:async) && args[:async]
      Logger.debug "starting async motel runner"
      @run_thread = Thread.new { run_cycle }
    else
      Logger.debug "starting motel runner"
      run_cycle
    end

  end

  # Stop locations movement
  def stop
    Logger.debug "stopping motel runner"
    @terminate = true
    @thread_pool.shutdown
    join
    Logger.debug "motel runner stopped"
  end

  # Block until runner is shutdown before returning
  def join
    @run_thread.join unless @run_thread.nil?
    @run_thread = nil
  end

  private

    # Internal helper method performing main runner operations
    def run_cycle
      # track time between runs
      start_time = Time.now

      until @terminate
        # copy locations into temp 2nd array so we're not holding up lock on locations array
        tlocations = []
        @locations_lock.synchronize {
          @locations.each { |loc| tlocations.push loc }
        }

        tlocations.each { |loc|
          @thread_pool.dispatch(loc) { |loc|
            Logger.debug "runner moving location #{loc.id} via #{loc.movement_strategy.class.to_s}"

            loc.movement_strategy.move loc, Time.now - start_time
            start_time = Time.now

            # TODO see if loc coordinates changed b4 doing this
            loc.movement_callbacks.each { |callback|
                callback.call(loc)
            }

            ## delay as long as the strategy tells us to
            sleep loc.movement_strategy.step_delay
          }
        }

        sleep @run_delay
      end
    end

end

end # module motel
