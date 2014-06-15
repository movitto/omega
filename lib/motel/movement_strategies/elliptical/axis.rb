# The Elliptcial MovementStrategy Axis Mixin
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel
module MovementStrategies
module EllipticalAxis
  # Direction vector corresponding to the major axis of the elliptical path
  attr_accessor :dmajx, :dmajy, :dmajz

  # Combined major direction vector
  def dmaj
    [@dmajx, @dmajy, @dmajz]
  end

  # Direction vector corresponding to the minor axis of the elliptical path
  attr_accessor :dminx, :dminy, :dminz

  # Combined minor direction vector
  def dmin
    [@dminx, @dminy, @dminz]
  end

  # Combined direction vector
  def direction
    dmaj + dmin
  end

  # Initialize axis from args
  #
  # Direction vectors will be normalized if not already
  def axis_from_args(args)
    @dmajx, @dmajy, @dmajz, @dminx, @dminy, @dminz =
      (args[:direction] || args['direction'] || Elliptical::DEFAULT_AXIS).flatten

    dmaj = args[:dmaj] || args['dmaj'] || [@dmajx, @dmajy, @dmajz]
    dmin = args[:dmin] || args['dmin'] || [@dminx, @dminy, @dminz]
    @dmajx, @dmajy, @dmajz = dmaj
    @dminx, @dminy, @dminz = dmin

    attr_from_args args,
      :dmajx =>   @dmajx, :dmajy =>   @dmajy, :dmajz =>   @dmajz,
      :dminx =>   @dminx, :dminy =>   @dminy, :dminz =>   @dminz

    @dmajx, @dmajy, @dmajz = Motel::normalize(@dmajx, @dmajy, @dmajz)
    @dminx, @dminy, @dminz = Motel::normalize(@dminx, @dminy, @dminz)
  end

  # Return bool indicating if major axis is valid
  def dmaj_valid?
    Motel::normalized?(@dmajx, @dmajy, @dmajz)
  end

  # Return bool indicating if minor axis is valid
  def dmin_valid?
    Motel::normalized?(@dminx, @dminy, @dminz)
  end

  # Return bool indicating if axis are orthogonal
  def axis_orthogonal?
    Motel::orthogonal?(@dmajx, @dmajy, @dmajz, @dminx, @dminy, @dminz)
  end

  # Return bool indicating if axis' are valid
  def axis_valid?
    dmaj_valid? && dmin_valid? && axis_orthogonal?
  end

  # Return axis attributes in json format
  def axis_attrs
    [:dmajx, :dmajy, :dmajz,
     :dminx, :dminy, :dminz]
  end

  # Return axis attributes in json fomrat
  def axis_json
    {:dmajx => dmajx,
     :dmajy => dmajy,
     :dmajz => dmajz,
     :dminx => dminx,
     :dminy => dminy,
     :dminz => dminz}
  end

  private

  ### internal helper movement methods

  # return the axis-angle representing the rotation of the
  # direction axis plane from the standard cartesian axis plane
  def axis_plane_rotation
    vectors = Motel::CARTESIAN_NORMAL_VECTOR +
              Motel.cross_product(dmajx,dmajy,dmajz,dminx,dminy,dminz)
    Motel.axis_angle(*vectors)
  end

  # return the axis-angle representing the rotation of the
  # major direction vector from the major direction
  # vector of the cartesian axis, rotated onto the plane
  # of the current axis (see #axis_plane_rotation above)
  def axis_rotation
    vectors =
      Motel.rotate(*Motel::MAJOR_CARTESIAN_AXIS, *axis_plane_rotation) + dmaj

    Motel.axis_angle(*vectors)
  end
end # module EllipticalAxis
end # module MovementStrategies
end # module Motel
