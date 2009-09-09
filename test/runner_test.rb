# runner tests, tests the runner module
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

class Stopped < MovementStrategy
   def move(location, elapsed_time)
   end
end

class RunnerTest < Test::Unit::TestCase
  def setup
     @callback_invoked = false
     @stopped_movement_strategy = Stopped.new({ :step_delay => 0.1 })
     @stopped_movement_strategy.movement_callbacks.push(Proc.new do |l|
        @callback_invoked = true
     end)
  end

  def teardown
  end

  def test_run_locations
     # create location heirarchy
     parent = Location.new
     parent.id = 1
     parent.movement_strategy = @stopped_movement_strategy

     child1 = Location.new :parent => parent, 
                            :x => 10, :y => 10, :z => 10
     child1.movement_strategy = @stopped_movement_strategy
     child1.id = 2

     child2 = Location.new :parent => parent, 
                            :x => -10, :y => -10, :z => -10
     child2.movement_strategy = @stopped_movement_strategy
     child2.id = 3

      # test the runner
      runner = Runner.new
      runner.run parent

      # make sure callback is invoked
      sleep(0.2)
      assert @callback_invoked

      # make sure runner is managed and a corresponding thread created
      assert_equal 1, runner.location_runners.size 
      assert ! runner.location_runners[0].run_thread.nil?

      # ensure registering a runner twice does nothing
      runner.run parent
      assert_equal 1, runner.location_runners.size 

      # register other locations
      runner.run child1
      runner.run child2
      assert_equal 3, runner.location_runners.size 

      assert ! runner.location_runners[1].run_thread.nil?
      assert ! runner.location_runners[2].run_thread.nil?

      # terminate the runner
      runner.terminate
      runner.location_runners.each { |runner|
        assert runner.run_thread.nil?
      }
  end

end
