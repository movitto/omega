# The Elliptcial MovementStrategy Path Mixin
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

# TODO cache calculated orbit properties / set in constructor /
#      return in json / filter in :get scope

module Motel
module MovementStrategies
module EllipticalPath
  # [CENTER, FOCI] value indicates if the parent
  #   of the location tracked by this strategy is at the center or the foci
  #   of the ellipse.
  #
  # Affects how elliptical path is calculated
  attr_accessor :relative_to

  # Describes the elliptical path through which the location moves
  attr_accessor :e, :p
  alias :eccentricity :e
  alias :eccentricity= :e=
  alias :semi_latus_rectum :p
  alias :semi_latus_rectum= :p=

  # Initialize path from args
  def path_from_args(args)
    attr_from_args args,
      :e           => nil,
      :p           => nil,
      :relative_to => Elliptical::CENTER
  end

  # Return boolean indicating eccentricity is valid
  def e_valid?
    @e.numeric? && @e >= 0 && @e <= 1
  end

  # Return boolean indicating semi latus rectum is valid
  def p_valid?
    @p.numeric? && @p > 0
  end

  # Return boolean indicating if relative_to is valid
  def relative_to_valid?
    [Elliptical::CENTER, Elliptical::FOCI].include?(@relative_to)
  end

  # Return boolean indicating path is valid
  def path_valid?
    e_valid? && p_valid? && relative_to_valid?
  end

  # Return path attributes
  def path_attrs
    [:e, :p, :relative_to]
  end

  # Return path attributes in json format
  def path_json
    {:e => e, :p => p,
     :relative_to => relative_to}
  end

  private
  ### internal helper movement methods

  # return the a,b intercepts of the ellipse
  # p = a(1 - e^2) = b^2 / a
  # e = sqrt(1 - (b/a)^2)
  def intercepts
    a = p / (1 - e**2)
    b = Math.sqrt(p * a)
    return a,b
  end

  # return the linear eccentricity of the ellipse
  # le = sqrt(a^2 - b^2)
  def linear_eccentricity
    a,b = intercepts
    Math.sqrt(a**2 - b**2);
  end

  # return the coordinates of the center position
  # C = (-direction_major) * le
  def center
    return 0,0,0 if relative_to == Elliptical::CENTER

    a,b = intercepts
    le  = linear_eccentricity

    centerX = -1 * dmajx * le;
    centerY = -1 * dmajy * le;
    centerZ = -1 * dmajz * le;
    return centerX, centerY, centerZ
  end

  # return the coordinates of a focus position
  # F = direction_major * le
  def focus
    return 0,0,0 if relative_to == Elliptical::FOCI

    a,b = intercepts
    le  = linear_eccentricity

    focusX = dmajx * le;
    focusY = dmajy * le;
    focusZ = dmajz * le;
    return focusX, focusY, focusZ
  end
end # module EllipticalPath
end # module MovementStrategies
end # module Motel
