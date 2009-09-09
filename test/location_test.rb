# location tests, tests the Location model
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

class LocationTest < Test::Unit::TestCase

  def setup
  end

  def teardown
    Location.destroy_all
  end

  def test_invalid_location
    location = Location.new
    flunk 'root location must be valid' unless location.valid?

    location.save!
    flunk 'default stopped movement strategy should be created upon save' if location.movement_strategy.nil? || location.movement_strategy.type != "Stopped"

    location2 = Location.new
    location2.location = location
    flunk 'location with parent must have x,y,z' if location2.valid?

    location.x = '420'
    flunk 'location with x must have parent' if location.valid?

    location.x = nil
    location.y = '840'
    flunk 'location with y must have parent' if location.valid?

    location.y = nil
    location.z = '1680'
    flunk 'location with z must have parent' if location.valid?
  end

  def test_location_totals
    grandparent = Location.new
    parent = Location.new({ :parent => grandparent, 
                            :x      => 14,
                            :y      => 24,
                            :z      => 42 })
    child = Location.new({  :parent => parent,
                            :x      => 123,
                            :y      => -846,
                            :z      => -93 })

    assert_equal 14 + 123, child.total_x
    assert_equal 24 - 846, child.total_y
    assert_equal 42 - 93,  child.total_z
  end

  # TODO the to_from_string test was written for an old implemenation of Location.to_s, update
  #def test_location_to_from_string
  #  fl = Location.new({:x => 145})
  #  assert_equal "x" + QPID_STRING_ATTR_DELIM + "145.0" + QPID_OBJ_DELIM * 2, fl.to_s

  #  lwm = Location.new({:parent_id => 15, :movement_strategy => Linear.new({:speed => 15, :direction_vector_x => 1}) })
  #  ls = lwm.to_s
  #  assert_equal "parent_id" + QPID_STRING_ATTR_DELIM + "15" + QPID_OBJ_DELIM + 
  #               "Linear" + QPID_STRING_DELIM + "speed" + QPID_STRING_ATTR_DELIM + "15.0" + 
  #               QPID_STRING_DELIM + "direction_vector_x" + QPID_STRING_ATTR_DELIM + "1.0" + QPID_OBJ_DELIM, ls

  #  lfs  = Location.from_s(ls)
  #  msfs = lfs.movement_strategy
  #  assert_equal 15, lfs.parent_id
  #  assert_equal Linear, msfs.class
  #  assert_equal 15, msfs.speed
  #  assert_equal 1, msfs.direction_vector_x

  #  lwc = Location.new
  #  lwp1 = Location.new({:parent => lwc })
  #  lwp2 = Location.new({:parent => lwc })
  #  lwp1.id = 420
  #  lwp2.id = 840
  #  lwc.locations.push(lwp1).push(lwp2)
  #  assert_equal QPID_OBJ_DELIM * 2 + "420" + QPID_LIST_DELIM + "840", lwc.to_s

  #  location = Location.new({ :parent_id => 10,
  #                            :x         => 5,
  #                            :y         => 10,
  #                            :z         => -20})
  #  location.id = 15

  #  ls = location.to_s
  #  assert_equal "id" + QPID_STRING_ATTR_DELIM + "15" + QPID_STRING_DELIM + "parent_id" + QPID_STRING_ATTR_DELIM + "10" +
  #               QPID_STRING_DELIM + "x" + QPID_STRING_ATTR_DELIM + "5.0" + QPID_STRING_DELIM + "y" + QPID_STRING_ATTR_DELIM + 
  #               "10.0" + QPID_STRING_DELIM + "z" + QPID_STRING_ATTR_DELIM + "-20.0" + QPID_OBJ_DELIM * 2, ls

  #  new_location = Location.from_s ls

  #  assert_equal 15,  new_location.id
  #  assert_equal 10,  new_location.parent_id
  #  assert_equal  5,  new_location.x
  #  assert_equal 10,  new_location.y
  #  assert_equal -20, new_location.z
  #end
end
