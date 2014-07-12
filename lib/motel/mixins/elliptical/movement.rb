# The Elliptcial MovementStrategy Movement Mixin
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/common'

# TODO use the Motel#elliptical_path helper method here
# TODO combine theta/coords_from_theta rotations

module Motel
module MovementStrategies
module EllipticalMovement
  # Distance the location moves per second
  attr_accessor :speed

  # Initialize movement from args
  def movement_from_args(args)
    attr_from_args args, :speed => nil
  end

  # Return bool indicating if speed is valid
  def speed_valid?
    @speed.numeric? && @speed > 0
  end

  # Return movement attributes
  def movement_attrs
    [:speed]
  end

  # Return movement attributes in json format
  def movement_json
    {:speed => speed}
  end

  # Move location along elliptical path
  def move_elliptical(loc, elapsed_seconds)
    # make sure location is on ellipse
    unless location_valid? loc
       cx,cy,cz = closest_coordinates loc
       ::RJR::Logger.warn "location #{loc} not on ellipse, adjusting to closest location #{cx},#{cy},#{cz} before moving"
       # FIXME raise error if cx,cy,cz is nil
       loc.x,loc.y,loc.z = cx,cy,cz
    end

    ::RJR::Logger.debug "moving location #{loc.id} via elliptical movement strategy"

    # calculate distance moved and update x,y,z accordingly
    distance = speed * elapsed_seconds

    nX,nY,nZ = coordinates_from_theta(theta(loc) + distance)
    loc.x = nX
    loc.y = nY
    loc.z = nZ
  end

  private
  ### internal helper movement methods

  # return the origin centered coordiates of a location
  def origin_centered_coordinates(location)
    cX,cY,cZ = center
    return location.x - cX,
           location.y - cY,
           location.z - cZ
  end

  # return the theta corresponding to the position of a
  # location on the elliptical path.
  #
  #  derived formula for theta from x,y,z elliptical path equations (see below) and linear transformations:
  #  theta = acos((minY * (x-cX) - minX * (y-cY))/(a*(minY * majX - minX * majY)))
  def theta(location)
    # center coordinate
    nx,ny,nz = origin_centered_coordinates location

    # rotate coordinate plane into 3d cartesian coordinate system...
    ar = axis_rotation
    ar[0] *= -1
    nx,ny,nz = Motel.rotate(nx, ny, nz, *ar)

    # ...then rotate ellipse into 2d cartesian coordiante system
    apr = axis_plane_rotation
    apr[0] *= -1
    nx,ny,nz = Motel.rotate(nx, ny, nz, *apr)
    # assert nz == 0

    # calculate theta
    a,b = intercepts
    t = Math.acos(nx/a) # should also == Math.asin(ny/b)

    # determine if current point is in negative quadrants of coordinate system
    below = ny < 0

    # adjust to compensate for acos loss if necessary
    t = 2 * Math::PI - t if (below)

    return t
  end

  # calculate the x,y,z coordinates of a location on the elliptical
  # path given its theta
  def coordinates_from_theta(theta)
    # calculate coordinates in 2d system
    a,b = intercepts
    x = a * Math.cos(theta)
    y = b * Math.sin(theta)

    # rotate it into 3d space
    apr = axis_plane_rotation
    nx,ny,nz = Motel.rotate(x, y, 0, *apr)

    # rotate to new axis
    ar = axis_rotation
    nx,ny,nz = Motel.rotate(nx, ny, nz, *ar)

    # center coordinate
    cX,cY,cZ = center
    nx = nx + cX
    ny = ny + cY
    nz = nz + cZ

    return nx,ny,nz
  end

  # return x,y,z coordinates of the closest point on the ellipse to the given location
  def closest_coordinates(location)
    t = theta location

    return nil if t.nan?

    return coordinates_from_theta(t)
  end

  public

  # Return boolean indicating if the given location is on the ellipse or not
  def location_valid?(location)
     x,y,z = closest_coordinates(location)

     return false if x.nil? || y.nil? || z.nil?
     return (x - location.x).round_to(4) == 0 &&
            (y - location.y).round_to(4) == 0 &&
            (z - location.z).round_to(4) == 0
  end
  alias :intersects? :location_valid?
end # module EllipticalMovement
end # module MovementStrategies
end # module Motel
