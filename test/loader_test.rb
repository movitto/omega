# loader tests, tests the loader module
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

class LoaderTest < Test::Unit::TestCase
  def setup
  end

  def teardown
     #Location.destroy_all
  end

  def test_load
     # create location heirarchy and save it
     parent = Location.new
     parent.movement_strategy = MovementStrategy::stopped

     child1 = Location.new :parent => parent, 
                            :x => 10, :y => 10, :z => 10
     child1.movement_strategy = MovementStrategy::stopped

     child2 = Location.new :parent => parent, 
                            :x => -10, :y => -10, :z => -10
     child2.movement_strategy = MovementStrategy::stopped

     parent.save!
     child1.save!
     child2.save!

     Loader.Load
     assert_equal Location.find(:all).size, Runner.get.location_runners.size
     Runner.get.location_runners.each { |runner|
         assert !runner.run_thread.nil?
     }
  end
end
