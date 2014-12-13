# Motel HasCoordinates Mixin.
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel

# Mixed into Location, provides coordinates accessors and helpers
module HasCoordinates
  # Coordinates relative to location's parent
  attr_accessor :x, :y, :z

  # Return coordinates attributes
  def coordinates_attrs
    [:x, :y, :z]
  end

  # Initialize default coordinates / coordinates from arguments
  def coordinates_from_args(args)
    @x, @y, @z = *(args[:coordinates] || args['coordinates'] || [])

    attr_from_args args, :x => @x, :y => @y, :z => @z

    # TODO use alternate conversions / raise error ?
    # (no parsing errors will be raised, invalid conversions will be set to 0)
    @x = @x.to_f unless @x.nil?
    @y = @y.to_f unless @y.nil?
    @z = @z.to_f unless @z.nil?
  end

  # Return bool indicating if coordatinates are valid
  def coordinates_valid?
    [@x, @y, @z].all? { |i| i.numeric? }
  end

  # Return this location's coordinates in an array
  #
  # @return [Array<Float,Float,Float>] array containing this
  # location's x,y,z coordinates
  def coordinates
    [@x, @y, @z]
  end
  alias :coords :coordinates

  # Set this location's coordiatnes
  def coordinates=(*c)
    c.flatten! if c.first.is_a?(Array)
    @x, @y, @z = *c
  end
  alias :coords= :coordinates=

  # Return the absolute 'x' value of this location,
  # eg the sum of the x value of this location and that of all its parents
  def total_x
    return 0 if parent.nil?
    return parent.total_x + x
  end

  # Return the absolute 'y' value of this location,
  # eg the sum of the y value of this location and that of all its parents
  def total_y
    return 0 if parent.nil?
    return parent.total_y + y
  end

  # Return the absolute 'z' value of this location,
  # eg the sum of the z value of this location and that of all its parents
  def total_z
    return 0 if parent.nil?
    return parent.total_z + z
  end

  # Return the distance between this location and specified coords
  #
  # @example
  #   loc1 = Motel::Location.new :x => 100
  #   loc2 = Motel::Location.new :x => 200
  #   loc1 - loc2      # => 100
  #   loc2 - loc1      # => 100
  #   loc1 - 100, 0, 0 # => 0
  def -(*coords)
    coords = coords.flatten
    coords = coords.first.coordinates if coords.length == 1 && coords.first.is_a?(Location)
    distance_from *coords
  end

  # Return the distance between this location and the specified point
  def distance_from(cx, cy, cz)
    dx = x - cx
    dy = y - cy
    dz = z - cz
    Motel.length(dx, dy, dz)
  end

  # Return distance from this location to origin
  def distance_from_origin
    distance_from 0, 0, 0
  end
  alias :scalar :distance_from_origin
  alias :abs :distance_from_origin


  # Return normalized direction vector from this location's coordinates to specified ones
  def direction_to(tx, ty, tz)
    dx = x - tx
    dy = y - ty
    dz = z - tz
    d = Motel.length(dx, dy, dz)
    [dx / d, dy / d, dz / d]
  end

  # Add specified quantities to each coordinate component and return new location
  #
  # @param [Array<Integer,Integer,Integer>,Array<Float,Float,Float>] values values to add to x,y,z coordinates respectively
  # @return [Motel::Location] new location with coordinates corresponding to those locally plus the specified values
  #
  # @example
  #   loc = Motel::Location.new(:id => 42, :x => 100, :y => -100, :z => -200)
  #   loc2 = loc + [100, 100, 100]
  #   loc2   # => loc-(200, 0, -100)
  #   loc    # => loc-42(100, -100, -200)
  def +(values)
    loc = Location.new
    loc.update(self)
    loc.x += values[0]
    loc.y += values[1]
    loc.z += values[2]
    loc
  end

  # Return coordinates in json format
  def coordinates_json
    {:x => x, :y => y, :z => z}
  end

  # Return coordinates in string format
  def coordinates_str
    (x.numeric? ? x.round_to(2).to_s : "") + "," +
    (y.numeric? ? y.round_to(2).to_s : "") + "," +
    (z.numeric? ? z.round_to(2).to_s : "")
  end

  # Return bool indicating if coordinates are equal to other's
  def coordinates_eql?(other)
    x == other.x && y == other.y && z == other.z
  end
end # module HasCoordinates
end # module Motel
