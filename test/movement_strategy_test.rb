# movement strategy tests, tests the MovementStrategy model
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

class MovementStrategyTest < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_invalid_movement_strategy
      movement_strategy = MovementStrategy.new

      movement_strategy.type = "Stopped"
      movement_strategy.step_delay = 10

      flunk "movement strategy should be valid" unless movement_strategy.valid?

      movement_strategy.type = nil
      flunk "movement strategy must have type" if movement_strategy.valid?

      movement_strategy.type = 'test'
      flunk "movement strategy must have valid type" if movement_strategy.valid?

      movement_strategy.type     = "Stopped"
      movement_strategy.step_delay = nil
      movement_strategy.valid?
      flunk "default step delay should be assigned to movement strategy" if movement_strategy.step_delay.nil? || !movement_strategy.valid?
  end

  def test_stopped_movement_strategy
     # setup test
     stopped = Stopped.new
     parent   = Location.new
     x = 50
     y = 100
     z = 200
     location = Location.new(:parent => parent,
                             :movement_strategy => stopped,
                             :x => 50, :y => 100, :z => 200)

     # make sure location does not move
     stopped.move location, 10
     assert_equal x, location.x
     assert_equal y, location.y
     assert_equal z, location.z

     stopped.move location, 50
     assert_equal x, location.x
     assert_equal y, location.y
     assert_equal z, location.z

     stopped.move location, 0
     assert_equal x, location.x
     assert_equal y, location.y
     assert_equal z, location.z
  end

  def test_linear_movement_strategy
     # ensure required linear parameters
     linear = Linear.new :step_delay => 5
     flunk "linear strategy without speed and direction vector should not be valid" if linear.valid?
     linear.speed = 10
     flunk "linear strategy without direction vector should not be valid" if linear.valid?
     linear.direction_vector_x = 5
     flunk "linear strategy with partial strategy direction vector should not be valid" if linear.valid?
     linear.direction_vector_y = linear.direction_vector_z = 5
     linear.speed = -10
     flunk "linear strategy with invalid speed should not be valid" if linear.valid?
     linear.speed = 20
     flunk "complete linear strategy should be valid" unless linear.valid?

     # ensure linear vector gets automatically normailized
     dx,dy,dz = normalize 5, 5, 5
     assert_equal dx, linear.direction_vector_x
     assert_equal dy, linear.direction_vector_y
     assert_equal dz, linear.direction_vector_z

     parent   = Location.new
     x = y = z = 20
     location = Location.new(:parent => parent,
                             :movement_strategy => linear,
                             :x => x, :y => y, :z => z)

     # move and validate
     linear.move location, 1
     assert_equal x + dx * linear.speed, location.x
     assert_equal y + dy * linear.speed, location.y
     assert_equal z + dz * linear.speed, location.z

     x = location.x
     y = location.y
     z = location.z

     linear.move location, 5
     assert_equal x + dx * linear.speed * 5, location.x
     assert_equal y + dy * linear.speed * 5, location.y
     assert_equal z + dz * linear.speed * 5, location.z
  end

  def test_elliptical_movement_strategy
     # ensure required elliptical parameters
     elliptical = Elliptical.new(:step_delay        => 5,
                                 :relative_to       => Elliptical::RELATIVE_TO_FOCI,
                                 :speed             => 1.57,
                                 :eccentricity      => 0.5,
                                 :semi_latus_rectum => 20,
                                 :direction_major_x => 1,
                                 :direction_major_y => 0,
                                 :direction_major_z => 0,
                                 :direction_minor_x => 0,
                                 :direction_minor_y => 1,
                                 :direction_minor_z => 0)
     flunk "complete elliptical strategy should be valid" unless elliptical.valid?

     elliptical.speed = nil
     flunk "elliptical strategy without speed should not be valid" if elliptical.valid?
     elliptical.speed = 20
     flunk "elliptical strategy with invalid speed should not be valid" if elliptical.valid?
     elliptical.speed = 1.57

     elliptical.eccentricity = nil
     flunk "elliptical strategy without eccentricity should not be valid" if elliptical.valid?
     elliptical.eccentricity = 1.5
     flunk "elliptical strategy with invalid eccentricity should not be valid" if elliptical.valid?
     elliptical.eccentricity = -0.3
     flunk "elliptical strategy with invalid eccentricity should not be valid" if elliptical.valid?
     elliptical.eccentricity = 0 # circle

     elliptical.semi_latus_rectum = nil
     flunk "elliptical strategy without semi_latum_rectum should not be valid" if elliptical.valid?
     elliptical.semi_latus_rectum = -5
     flunk "elliptical strategy with invalid semi_latum_rectum should not be valid" if elliptical.valid?
     elliptical.semi_latus_rectum = 1

     elliptical.relative_to = nil
     flunk "elliptical strategy without relative_to should not be valid" if elliptical.valid?
     elliptical.relative_to = "foobar"
     flunk "elliptical strategy with invalid relative_to should not be valid" if elliptical.valid?
     elliptical.relative_to = Elliptical::RELATIVE_TO_CENTER

     elliptical.direction_major_x = nil
     flunk "elliptical strategy without major direction vector should not be valid" if elliptical.valid?
     elliptical.direction_major_x = 1

     elliptical.direction_minor_x = nil
     flunk "elliptical strategy without minor direction vector should not be valid" if elliptical.valid?
     elliptical.direction_minor_x = 0

     elliptical.direction_major_x = elliptical.direction_major_y = elliptical.direction_major_z = 0.3333333
     flunk "elliptical strategy with non orthogonal direction vectors should not be valid" if elliptical.valid?
     elliptical.direction_major_y = elliptical.direction_major_z = 0
     elliptical.direction_major_x = 1

     # ensure elliptical axis vectors get automatically normailized
     elliptical.direction_minor_x = elliptical.direction_minor_y = elliptical.direction_minor_z = 
       elliptical.direction_major_x = elliptical.direction_major_y = elliptical.direction_major_z = 5
     elliptical.valid?
     dx,dy,dz = normalize 5,5,5
     assert_equal dx, elliptical.direction_major_x
     assert_equal dy, elliptical.direction_major_y
     assert_equal dz, elliptical.direction_major_z
     assert_equal dx, elliptical.direction_minor_x
     assert_equal dy, elliptical.direction_minor_y
     assert_equal dz, elliptical.direction_minor_z
     elliptical.direction_minor_y = elliptical.direction_major_x = 1 
     elliptical.direction_minor_x = elliptical.direction_minor_z = 
       elliptical.direction_major_y = elliptical.direction_major_z = 0

     parent   = Location.new
     x = 1
     y = z = 0
     location = Location.new(:parent => parent,
                             :movement_strategy => elliptical,
                             :x => x, :y => y, :z => z)

     # move and validate
     elliptical.move location, 1
     assert_equal 0, (0 - location.x).abs.round_to(2)
     assert_equal 0, (1 - location.y).abs.round_to(2)
     assert_equal 0, (0 - location.z).abs.round_to(2)

     elliptical.move location, 1
     assert_equal 0, (-1 - location.x).abs.round_to(2)
     assert_equal 0, (0  - location.y).abs.round_to(2)
     assert_equal 0, (0  - location.z).abs.round_to(2)

     elliptical.move location, 1
     assert_equal 0, (0  - location.x).abs.round_to(2)
     assert_equal 0, (-1 - location.y).abs.round_to(2)
     assert_equal 0, (0  - location.z).abs.round_to(2)

     elliptical.move location, 1
     assert_equal 0, (1  - location.x).abs.round_to(2)
     assert_equal 0, (0 - location.y).abs.round_to(2)
     assert_equal 0, (0  - location.z).abs.round_to(2)
  end

  # TODO the to_from_string test was written for an old implemenation of MovementStrategy.to_s, update
  #def test_movement_strategy_to_from_string
  #   ms = MovementStrategy.new
  #   assert_equal "" + QPID_STRING_DELIM, ms.to_s

  #   ms = Stopped.new
  #   assert_equal "Stopped" + QPID_STRING_DELIM, ms.to_s

  #   ms = MovementStrategy.from_s ms.to_s
  #   assert_equal Stopped, ms.class

  #   ms = Linear.new(:speed => 20)
  #   assert_equal "Linear" + QPID_STRING_DELIM + "speed" + QPID_STRING_ATTR_DELIM + "20.0", ms.to_s

  #   ms = Linear.new(:speed => 420,
  #                   :direction_vector_x => -1,
  #                   :direction_vector_y => 0,
  #                   :direction_vector_z => 0.5)

  #   assert_equal "Linear" + QPID_STRING_DELIM + "speed" + QPID_STRING_ATTR_DELIM + "420.0" + 
  #                QPID_STRING_DELIM + "direction_vector_x" + QPID_STRING_ATTR_DELIM + "-1.0" + QPID_STRING_DELIM +
  #                "direction_vector_y" + QPID_STRING_ATTR_DELIM + "0.0" + QPID_STRING_DELIM + "direction_vector_z" +
  #                QPID_STRING_ATTR_DELIM + "0.5", ms.to_s

  #   ms = MovementStrategy.from_s ms.to_s
  #   assert_equal Linear, ms.class
  #   assert_equal 420,  ms.speed
  #   assert_equal -1,  ms.direction_vector_x
  #   assert_equal  0,  ms.direction_vector_y
  #   assert_equal 0.5, ms.direction_vector_z

  #   ms = Elliptical.new(:speed => 1.57)
  #   assert_equal "Elliptical" + QPID_STRING_DELIM + "speed" + QPID_STRING_ATTR_DELIM + "1.57", ms.to_s

  #   ms = Elliptical.new(:speed => 0.41,
  #                       :eccentricity => 0.75,
  #                       :semi_latus_rectum => 150,
  #                       :relative_to => Elliptical::RELATIVE_TO_CENTER,
  #                       :direction_major_x => -1,
  #                       :direction_major_y => -0.5,
  #                       :direction_major_z => 0.75,
  #                       :direction_minor_x => -1,
  #                       :direction_minor_y => -0.5,
  #                       :direction_minor_z => 0.75)

  #   assert_equal "Elliptical" + QPID_STRING_DELIM + "speed" + QPID_STRING_ATTR_DELIM + "0.41" + 
  #                QPID_STRING_DELIM + "eccentricity" + QPID_STRING_ATTR_DELIM + "0.75" + 
  #                QPID_STRING_DELIM + "semi_latus_rectum" + QPID_STRING_ATTR_DELIM + "150.0" +
  #                QPID_STRING_DELIM + "relative_to" + QPID_STRING_ATTR_DELIM + Elliptical::RELATIVE_TO_CENTER +
  #                QPID_STRING_DELIM + "direction_major_x" + QPID_STRING_ATTR_DELIM + "-1.0" +
  #                QPID_STRING_DELIM + "direction_major_y" + QPID_STRING_ATTR_DELIM + "-0.5" + 
  #                QPID_STRING_DELIM + "direction_major_z" + QPID_STRING_ATTR_DELIM + "0.75" +
  #                QPID_STRING_DELIM + "direction_minor_x" + QPID_STRING_ATTR_DELIM + "-1.0" +
  #                QPID_STRING_DELIM + "direction_minor_y" + QPID_STRING_ATTR_DELIM + "-0.5" + 
  #                QPID_STRING_DELIM + "direction_minor_z" + QPID_STRING_ATTR_DELIM + "0.75", ms.to_s

  #   ms = MovementStrategy.from_s ms.to_s
  #   assert_equal Elliptical, ms.class
  #   assert_equal 0.41,  ms.speed
  #   assert_equal 0.75,  ms.eccentricity
  #   assert_equal 150,   ms.semi_latus_rectum
  #   assert_equal Elliptical::RELATIVE_TO_CENTER,  ms.relative_to
  #   assert_equal  -1,    ms.direction_major_x
  #   assert_equal  -0.5,  ms.direction_major_y
  #   assert_equal  0.75,  ms.direction_major_z
  #   assert_equal  -1,    ms.direction_minor_x
  #   assert_equal  -0.5,  ms.direction_minor_y
  #   assert_equal  0.75,  ms.direction_minor_z
  #end
end
