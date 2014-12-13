# The Elliptcial MovementStrategy Path Mixin
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

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
      :relative_to => Elliptical::CENTER,

      # see note in scoped_path_attrs
      :a           => nil,
      :b           => nil,
      :le          => nil

      center_from_args args
      focus_from_args args
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
  def scoped_path_attrs(scope)
    case(scope)

    # These are only path attributes accessible through rjr interface
    # (for both retrieval / creation). Other attributes are specified
    # in json / accepted in constructor to optimize internal use in
    # elliptical movement operations
    when :create, :get
      [:e, :p, :relative_to]
    end
  end

  # Return path attributes in json format
  def path_json
    {:e => e, :p => p,
     :relative_to => relative_to,

     # see note in scoped_path_attrs
     :a => a, :b => b, :le => le,
     :center => center,
     :focus => focus}
  end

  attr_accessor :a, :b

  # return the a,b intercepts of the ellipse
  # p = a(1 - e^2) = b^2 / a
  # e = sqrt(1 - (b/a)^2)
  def intercepts
    cannot_calc = (p.nil? || e.nil?) && (@a.nil? || @b.nil?)
    return nil, nil if cannot_calc
    @a ||= p / (1 - e**2)
    @b ||= Math.sqrt(p * @a)
    return @a,@b
  end

  # return the linear eccentricity of the ellipse
  # le = sqrt(a^2 - b^2)
  def linear_eccentricity
    a,b = intercepts
    cannot_calc = (a.nil? || b.nil?) && @le.nil?
    return nil if cannot_calc
    @le ||= Math.sqrt(a**2 - b**2);
  end
  alias :le :linear_eccentricity
  attr_writer :le

  attr_accessor :centerX, :centerY, :centerZ

  # Initialize center from args
  def center_from_args(args)
    if relative_to == Elliptical::CENTER
      @centerX = @centerY = @centerZ = 0

    elsif args.has_key?(:center)
      @centerX, @centerY, @centerZ = *args[:center]

    elsif args.has_key?('center')
      @centerX, @centerY, @centerZ = *args['center']
    end
  end

  # return the coordinates of the center position
  # C = (-direction_major) * le
  def center
    le  = linear_eccentricity
    cannot_calc = (!dmaj_valid? || le.nil?) && @centerX.nil?
    return nil, nil, nil if cannot_calc

    @centerX ||= -1 * dmajx * le
    @centerY ||= -1 * dmajy * le
    @centerZ ||= -1 * dmajz * le
    return @centerX, @centerY, @centerZ
  end

  # Set center coordinates
  def center=(*coords)
    coords = coords.flatten
    @centerX, @centerY, @centerZ = *coords
  end

  # Initialize focus from args
  def focus_from_args(args)
    if relative_to == Elliptical::FOCI
      @focusX = @focusY = @focusZ = 0

    elsif args.has_key?(:focus)
      @focusX, @focusY, @focusZ = *args[:focus]

    elsif args.has_key?('focus')
      @focusX, @focusY, @focusZ = *args['focus']
    end
  end

  attr_accessor :focusX, :focusY, :focusZ

  # return the coordinates of a focus position
  # F = direction_major * le
  def focus
    le  = linear_eccentricity
    cannot_calc = (!dmaj_valid? || le.nil?) && @focusX.nil?
    return nil, nil, nil if cannot_calc

    @focusX ||= dmajx * le
    @focusY ||= dmajy * le
    @focusZ ||= dmajz * le
    return @focusX, @focusY, @focusZ
  end
end # module EllipticalPath
end # module MovementStrategies
end # module Motel
