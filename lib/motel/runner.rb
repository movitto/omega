# Defines the LocationRunner and Runner classes, core to the motel engine,
# and is responsible for managing locations and moving them according to
# their corresponding movement_strategies
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'thread'
require 'singleton'

module Motel

# Motel::Runner is a singleton class/object which acts as the primary
# mechanism to run locations in the system. It contains a thread pool
# which contains a specified number of threads which to move the managed
# locations in accordance to their location strategies.
class Runner
  include Singleton

  # For testing purposes
  attr_reader :terminate, :run_thread

  def initialize(args = {})
    # is set to true upon runner termination
    @terminate = false

    # TODO use ruby tree to store locations w/ heirarchy
    # management queues, locations to be scheduled and locations to be run
    @schedule_queue = []
    @run_queue = []


    # locks protecting queues from concurrent access and conditions indicating queues have items
    @schedule_lock  = Mutex.new
    @run_lock       = Mutex.new
    @schedule_cv    = ConditionVariable.new
    @run_cv         = ConditionVariable.new

    @run_thread = nil
  end

  # Return complete list of locations being managed/tracked
  def locations
    # need conccurrent protection here, or copy the elements into another array and return that?
    @schedule_queue + @run_queue
  end


  # Empty the list of locations being managed/tracked
  def clear
    @schedule_lock.synchronize {
      @run_lock.synchronize {
        @schedule_queue.clear
        @run_queue.clear
    }}
  end

  # Add location to runner to be managed, after this is called, the location's
  # movement strategy's move method will be invoked periodically
  def run(location)
    @schedule_lock.synchronize {
      # autogenerate location.id if nil
      if location.id.nil?
        @run_lock.synchronize {
          i = 1
          until false
            break if @schedule_queue.find { |l| l.id == i }.nil? && @run_queue.find { |l| l.id == i }.nil?
            i += 1
          end
          location.id = i
        }
      end

      RJR::Logger.debug "adding location #{location.id} to runner queue"
      @schedule_queue.push location
      @schedule_cv.signal
    }
    return location
  end

  # Wrapper around run, except return 'self' when done
  def <<(location)
    run(location)
    return self
  end

  # Start moving the locations. If :async => true is passed in, this will immediately
  # return, else this will block until stop is called.
  def start(args = {})
    @num_threads = 5
    @num_threads = args[:num_threads] if args.has_key? :num_threads
    @terminate = false

    if args.has_key?(:async) && args[:async]
      RJR::Logger.debug "starting async motel runner"
      @run_thread = Thread.new { run_cycle }
    else
      RJR::Logger.debug "starting motel runner"
      run_cycle
    end

  end

  # Stop locations movement
  def stop
    RJR::Logger.debug "stopping motel runner"
    @terminate = true
    @schedule_lock.synchronize {
      @schedule_cv.signal
    }
    @run_lock.synchronize {
      @run_cv.signal
    }
    join
    RJR::Logger.debug "motel runner stopped"
  end

  # Block until runner is shutdown before returning
  def join
    @run_thread.join unless @run_thread.nil?
    @run_thread = nil
  end

  private

    # Internal helper method performing main runner operations
    def run_cycle
      # location ids which are currently being run -> their run timestamp
      location_timestamps = {}

      # scheduler thread, to add locations to the run queue
      scheduler = Thread.new {
        until @terminate
          tqueue       = []
          locs_to_run  = []
          empty_queue  = true
          min_delay    = nil

          @schedule_lock.synchronize {
            # if no locations are to be scheduled, block until there are
            @schedule_cv.wait(@schedule_lock) if @schedule_queue.empty?
            @schedule_queue.each { |l| tqueue << l }
          }

          # run through each location to be scheduled to run, see which ones are due
          tqueue.each { |loc|
            location_timestamps[loc.id] = Time.now unless location_timestamps.has_key?(loc.id)
            locs_to_run << loc if loc.movement_strategy.step_delay < Time.now - location_timestamps[loc.id]
          }

          # add those the the run queue, signal runner to start operations if blocking
          @schedule_lock.synchronize {
            @run_lock.synchronize{
              locs_to_run.each { |loc| @run_queue << loc ; @schedule_queue.delete(loc) }
              empty_queue = (@schedule_queue.size == 0)
              @run_cv.signal unless locs_to_run.empty?
            }
          }

          # if there are locations still to be scheduled, sleep for the smallest step_delay
          unless empty_queue
            # we use locations instead of @schedule_queue here since a when the scheduler is
            # sleeping a loc w/ a smaller step_delay may complete running and be added back to the scheduler
            min_delay= locations.sort { |a,b| 
              a.movement_strategy.step_delay <=> b.movement_strategy.step_delay 
            }.first.movement_strategy.step_delay
            sleep min_delay
          end
        end
      }

      # until we are told to stop
      until @terminate
        locs_to_schedule = []
        tqueue           = []

        @run_lock.synchronize{
          # wait until we have locations to run
          @run_cv.wait(@run_lock) if @run_queue.empty?
          @run_queue.each { |l| tqueue << l }
        }

        # run through each location to be run, perform actual movement, invoke callbacks
        tqueue.each { |loc|
          RJR::Logger.debug "runner moving location #{loc.id} at #{loc.coordinates.join(",")} via #{loc.movement_strategy.class.to_s}"

          # store the old location coordinates for comparison after the movement
          old_coords = [loc.x, loc.y, loc.z]

          elapsed = Time.now - location_timestamps[loc.id]
          loc.movement_strategy.move loc, elapsed 
          location_timestamps[loc.id] = Time.now

          # TODO invoke these async so as not to hold up the runner
          # make sure to keep these in sync w/ those invoked in the simrpc adapter "update_location" handler
          loc.movement_callbacks.each { |callback|
            callback.invoke(loc, *old_coords)
          }
          loc.proximity_callbacks.each { |callback|
            callback.invoke(loc)
          }

          locs_to_schedule << loc
        }

        # add locations back to schedule queue
        @run_lock.synchronize{
          @schedule_lock.synchronize{
            locs_to_schedule.each { |loc| @schedule_queue << loc ; @run_queue.delete(loc) }
            @schedule_cv.signal unless locs_to_schedule.empty?
          }
        }
      end

      scheduler.join
    end

end

end # module motel
