# Motel Trackable Mixin.
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'time'

module Motel

# Mixed into Location, provides trackable attributes
module Trackable
  # Distance moved since the last reset
  attr_accessor :distance_moved

  # Angle rotated since the last reset
  attr_accessor :angle_rotated

  # Time the location was last moved.
  # Used internally in the motel subsystem
  attr_accessor :last_moved_at

  # Return all trackable attributes
  def trackable_attrs
    [:distance_moved, :angle_rotated, :last_moved_at]
  end

  # Return updatable trackable attributes
  def updatable_trackable_attrs
    [:last_moved_at]
  end

  # Initialize default trackable state / trackable state from args
  def trackable_state_from_args(args)
    attr_from_args args, :distance_moved => @distance_moved,
                         :angle_rotated  => @angle_rotated,
                         :last_moved_at  => nil

    @last_moved_at = Time.parse(@last_moved_at) if @last_moved_at.is_a?(String)
  end

  # Resets attributes used to internally track location
  def reset_tracked_attributes
    @distance_moved = 0
    @angle_rotated  = 0
  end

  # Return trackable properties in json format
  def trackable_json
    {:distance_moved => distance_moved,
     :angle_rotated  => angle_rotated,
     :last_moved_at  => last_moved_at.nil? ? nil : last_moved_str}
  end

  # Return last moved in string format
  def last_moved_str
    last_moved_at.strftime("%d %b %Y %H:%M:%S.%5N")
  end

  # Return time since last movement
  def time_since_movement
    last_moved_at.nil? ? nil : (Time.now - last_moved_at)
  end
end # module Trackable
end # module Motel
