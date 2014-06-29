# Motel HasOrientation Mixin.
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel

# Mixed into Location, provides orientation accessors and helpers
module HasOrientation
  # Unit vector corresponding to Orientation of the location
  attr_accessor :orientation_x, :orientation_y, :orientation_z
  alias :orx :orientation_x
  alias :orx= :orientation_x=
  alias :ory :orientation_y
  alias :ory= :orientation_y=
  alias :orz :orientation_z
  alias :orz= :orientation_z=

  # Return orientation attributes
  def orientation_attrs
    [:orientation_x, :orientation_y, :orientation_z]
  end

  # Initialize default orientation / orientation from arguments
  def orientation_from_args(args)
    @orientation_x, @orientation_y, @orientation_z =
      *(args[:orientation] || args['orientation'] || [])

    attr_from_args args,
      :orientation_x => @orientation_x,
      :orientation_y => @orientation_y,
      :orientation_z => @orientation_z,
      :orx           => @orientation_x,
      :ory           => @orientation_y,
      :orz           => @orientation_z

    # TODO use alternate conversions / raise error ?
    # (no parsing errors will be raised, invalid conversions will be set to 0)
    @orientation_x = @orientation_x.to_f unless @orientation_x.nil?
    @orientation_y = @orientation_y.to_f unless @orientation_y.nil?
    @orientation_z = @orientation_z.to_f unless @orientation_z.nil?
  end

  # Return bool indicating if orientation is valid
  def orientation_valid?
    [@orientation_x,@orientation_y, @orientation_z].all? { |i| i.numeric? }
  end

  # Return this location's orientation in an array
  def orientation
    [@orientation_x, @orientation_y, @orientation_z]
  end

  # Set this location's orientation
  def orientation=(*o)
    o.flatten! if o.first.is_a?(Array)
    @orientation_x, @orientation_y, @orientation_z = *o
  end

  # Return boolean indicating if location is oriented towards the specified coordinate
  def oriented_towards?(x, y, z)
    orientation_difference(x, y, z).first == 0
  end

  # Return axis angle between location's orientation and the specified coordinate.
  def orientation_difference(x, y, z)
    dx = x - @x ; dy = y - @y ; dz = z - @z
    raise ArgumentError if dx == 0 && dy == 0 && dz == 0
    #return [0, 0, 0, 1] if dx == 0 && dy == 0 && dz == 0
    Motel.axis_angle(orx, ory, orz, dx, dy, dz)
  end

  # Return orientation in json format
  def orientation_json
    {:orientation_x => orientation_x,
     :orientation_y => orientation_y,
     :orientation_z => orientation_z}
  end

  # Return orientation in string format
  def orientation_str
    (orx.numeric? ? orx.round_to(2).to_s : "") + "," +
    (ory.numeric? ? ory.round_to(2).to_s : "") + "," +
    (orz.numeric? ? orz.round_to(2).to_s : "")
  end

  # Return bool indicating if orientation is equal to other's
  def orientation_eql?(other)
    orx == other.orx && ory == other.ory && orz == other.orz
  end
end # module HasOrientation
end # module Motel
