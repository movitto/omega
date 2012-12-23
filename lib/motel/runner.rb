# Defines the Runner class, core to the motel engine,
# and is responsible for managing locations and moving them according to
# their corresponding movement_strategies
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'thread'
require 'singleton'
require 'rjr/common'

module Motel

# Motel::Runner is a singleton class/object which acts as the primary
# mechanism to run locations in the system.
class Runner
  include Singleton

   # Runner initializer
   #
   # @param [Hash] args hash of options to initialize runner with, currently unused
  def initialize(args = {})
    # is set to true upon runner termination
    @terminate = false

    @locations      = []
    @timestamps     = {}
    @locations_lock  = Mutex.new

    @next_id = 1
    @delay   = 1
  end

  # Run the specified block of code as a protected operation.
  #
  # This should be used when updating any motel entities outside
  # the scope of runner operations to protect them from concurrent access.
  #
  # @param [Array<Object>] args catch-all array of arguments to pass to block on invocation
  # @param [Callable] bl block to invoke
  def safely_run(*args, &bl)
    @locations_lock.synchronize {
      bl.call *args
    }
  end


  # Return complete list of locations being managed/tracked
  #
  # @return [Array<Motel::Location>]
  def locations
    @locations_lock.synchronize { @locations }
  end

  # Return boolean indicating if the specified location id is tracked by this runner
  #
  # @param [Integer] id id of location to look for
  # @return [true,false] indicating if location is tracked locally
  def has_location?(id)
    !self.locations.find { |l| l.id == id }.nil?
  end

  # Empty the list of locations being managed/tracked
  def clear
    @locations_lock.synchronize { @locations.clear }
  end

  # Add location to runner to be managed.
  #
  # After this is called, the location's movement strategy's move method will be invoked periodically
  # @param [Motel::Location] location location to add the the run queue
  # @return [Motel::Location] location just added
  def run(location)
    @locations_lock.synchronize {
      # autogenerate location.id if nil
      if location.id.nil?
        @next_id  += 1 until @locations.find { |l| l.id == @next_id }.nil?
        location.id = @next_id
      end

      RJR::Logger.debug "adding location #{location.id} to runner"
      @locations.push location
      @timestamps[location.id] = Time.now

      # find smallest step_delay
      @delay =
        @locations.sort { |a,b| 
          a.movement_strategy.step_delay <=> b.movement_strategy.step_delay 
        }.first.movement_strategy.step_delay

      # TODO wake up run_thread
    }
    return location
  end

  # Wrapper around run, except return 'self' when done
  def <<(location)
    run(location)
    return self
  end

  # Start running the locations.
  def start
    return unless @run_thread.nil?
    @terminate = false

    RJR::Logger.debug "starting motel runner"
    @run_thread = Thread.new { run_cycle }
  end

  # Stop locations movement
  def stop
    RJR::Logger.debug "stopping motel runner"
    @terminate = true
    join
    RJR::Logger.debug "motel runner stopped"
  end

  # Block until runner is shutdown before returning
  def join
    @run_thread.join unless @run_thread.nil?
    @run_thread = nil
  end

  # Save state of the runner to specified io stream
  def save_state(io)
    @locations_lock.synchronize {
      @locations.each { |loc| io.write loc.to_json + "\n" }
    }
  end

  # Restore state of the runner from the specified io stream
  def restore_state(io)
    io.each { |json|
      entity = JSON.parse(json)
      if entity.is_a?(Motel::Location)
        run entity
      end
    }
  end

  private

    # Internal helper method performing main runner operations
    def run_cycle
      until @terminate
        self.locations.each { |loc|
          if (Time.now - @timestamps[loc.id]) > loc.movement_strategy.step_delay
            RJR::Logger.debug "runner moving location #{loc.id} at #{loc.coordinates.join(",")} via #{loc.movement_strategy.to_s}"
            #RJR::Logger.debug "#{loc.movement_callbacks.length} movement callbacks, #{loc.proximity_callbacks.length} proximity callbacks"

            # store the old location coordinates for comparison after the movement
            old_coords = [loc.x, loc.y, loc.z]

            elapsed = Time.now - @timestamps[loc.id]
            loc.movement_strategy.move loc, elapsed
            @timestamps[loc.id] = Time.now

            # TODO invoke these async so as not to hold up the runner
            # TODO delete movement callbacks after they are invoked?
            # TODO prioritize callbacks registered over the local rjr transport
            #      over others
            # make sure to keep these in sync w/ those invoked in the rjr adapter "update_location" handler
            loc.movement_callbacks.each { |callback|
              callback.invoke(loc, *old_coords)
            }
          end
        }

        # invoke all proximity_callbacks
        # see comments about movement_callbacks above
        @locations.each { |loc|
          loc.proximity_callbacks.each { |callback|
            callback.invoke(loc)
          }
        }

        sleep @delay
      end
    end
end

end # module motel
