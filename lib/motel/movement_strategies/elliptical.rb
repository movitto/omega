# The Elliptcial MovementStrategy model definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/errors'
require 'motel/movement_strategy'

require 'omega/common'
require 'rjr/common'

# FIXME use the Motel#elliptical_path helper method here

module Motel
module MovementStrategies

# The Elliptical MovementStrategy moves a location
# on an elliptical path described by major/minor
# axis direction vectors, and an eccentricity /
# semi_latus_rectum.
#
# The path equation also depends on the value of the relative_to
# field indicating if the parent location
# is the center or a foci of the ellipse.
# Lastly a speed value is required indicating the
# angular velocity of the location.
#
# To be valid you must specify eccentricity, semi_latus_rectum, and speed
# at a minimum
class Elliptical < MovementStrategy
   # Indicates that parent location is at center of elliptical path
   CENTER = "center"

   # Indicates that parent location is at one of the focis of the elliptical path
   FOCI   = "foci"

   # [CENTER, FOCI] value indicates if the parent
   #   of the location tracked by this strategy is at the center or the foci
   #   of the ellipse.
   #
   # Affects how elliptical path is calculated
   attr_accessor :relative_to

   # Distance the location moves per second
   attr_accessor :speed

   # Describes the elliptical path through which the location moves
   attr_accessor :e, :p
   alias :eccentricity :e
   alias :eccentricity= :e=
   alias :semi_latus_rectum :p
   alias :semi_latus_rectum= :p=

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

   # Motel::MovementStrategies::Elliptical initializer
   #
   # Direction vectors will be normalized if not already
   #
   # @param [Hash] args hash of options to initialize the elliptical movement strategy with
   # @option args [Array<Float>] :direction array containing x,y,z coords of major and minor direction vectors
   # @option args [Float] :dmajx x coordinate of major direction vector
   # @option args [Float] :dmajy y coordinate of major direction vector
   # @option args [Float] :dmajz z coordinate of major direction vector
   # @option args [Float] :dminx x coordinate of minor direction vector
   # @option args [Float] :dminy y coordinate of minor direction vector
   # @option args [Float] :dminz z coordinate of minor direction vector
   # @option args [Float] :speed speed to assign to movement strategy
   # @option args [CENTER, FOCI] :relative_to how the parent location is related to this elliptical path
   # @option args [Float] :e eccentricity to assign to elliptical path
   # @option args [Float] :p semi latus rectum to assign to elliptical path
   # @raise [Motel::InvalidMovementStrategy] if movement strategy is not valid (see {#valid?})
   def initialize(args = {})
      @dmajx, @dmajy, @dmajz, @dminx, @dminy, @dminz =
        (args[:direction] || args['direction'] || [1,0,0,0,1,0]).flatten

      dmaj = args[:dmaj] || args['dmaj'] || [@dmajx,@dmajy,@dmajz]
      dmin = args[:dmin] || args['dmin'] || [@dminx,@dminy,@dminz]
      @dmajx, @dmajy, @dmajz = dmaj
      @dminx, @dminy, @dminz = dmin

     attr_from_args args,
       :relative_to  => CENTER,
       :speed => nil, :e => nil, :p => nil,
       :dmajx =>   @dmajx, :dmajy =>   @dmajy, :dmajz =>   @dmajz,
       :dminx =>   @dminx, :dminy =>   @dminy, :dminz =>   @dminz

     super(args)

     @dmajx, @dmajy, @dmajz = Motel::normalize(@dmajx, @dmajy, @dmajz)
     @dminx, @dminy, @dminz = Motel::normalize(@dminx, @dminy, @dminz)
   end

   # Return boolean indicating if this movement strategy is valid
   #
   # Tests the various attributes of the elliptical movement strategy, returning 'true'
   # if everything is consistent, else false.
   #
   # Currently tests
   # * direction vectors are normalized
   # * direction vectors are orthogonal
   # * eccentricity is a valid numeric > 0
   # * semi latus rectum is a valid numeric > 0
   # * speed is a valid numeric > 0
   # * relative_to is CENTER or FOCI
   def valid?
     Motel::normalized?(@dmajx, @dmajy, @dmajz) &&
     Motel::normalized?(@dminx, @dminy, @dminz) &&
     Motel::orthogonal?(@dmajx, @dmajy, @dmajz, @dminx, @dminy, @dminz) &&
     @e.numeric? && @e >= 0 && @e <= 1 &&
     @p.numeric? && @p > 0 &&
     @speed.numeric? && @speed > 0 &&
     [CENTER, FOCI].include?(@relative_to)
   end

   # Implementation of {Motel::MovementStrategy#move}
   def move(loc, elapsed_seconds)
     # make sure this movement strategy is valid
     unless valid?
        ::RJR::Logger.warn "elliptical movement strategy not valid, not proceeding with move"
        return
     end

     # TODO validation / adjustment & theta computation / updating below
     # results in alot of redundant calls (recomputing theta & coords).
     # Optimize here or in new movement strategy that doesn't check
     # constraint / stores theta internally / etc

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

   # Convert movement strategy to json representation and return it
   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay   => step_delay,
                         :speed        => speed,
                         :relative_to  => relative_to,
                         :e => e,
                         :p => p,
                         :dmajx => dmajx,
                         :dmajy => dmajy,
                         :dmajz => dmajz,
                         :dminx => dminx,
                         :dminy => dminy,
                         :dminz => dminz }
     }.to_json(*a)
   end

   # Convert movement strategy to human readable string and return it
   def to_s
     "elliptical-(rt_#{relative_to}/s#{speed}/e#{e}/p#{p}/d#{direction})"
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
      return 0,0,0 if relative_to == CENTER

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
      return 0,0,0 if relative_to == FOCI

      a,b = intercepts
      le  = linear_eccentricity

      focusX = dmajx * le;
      focusY = dmajy * le;
      focusZ = dmajz * le;
      return focusX, focusY, focusZ
    end

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
   # TODO replace w/ intersects (below) ?
   def location_valid?(location)
      x,y,z = closest_coordinates(location)

      return false if x.nil? || y.nil? || z.nil?
      return (x - location.x).round_to(4) == 0 &&
             (y - location.y).round_to(4) == 0 &&
             (z - location.z).round_to(4) == 0
   end


   def random_coordinates
     coordinates_from_theta(Math.random * 2 * Math::PI)
   end

   #def intersects?(loc)
   #  coordinates_from_theta(theta(loc)) == [loc.x, loc.y, loc.z]
   #end
   alias :intersects? :location_valid?

   # Generate and return a random elliptical movement strategy
   def self.random(args = {})
     dimensions  = args[:dimensions]  || 3
     relative_to = args[:relative_to] || CENTER

     min_e = min_p = min_s = 0
     min_e = args[:min_e] if args.has_key?(:min_e)
     min_p = args[:min_p] if args.has_key?(:min_p)
     min_s = args[:min_s] if args.has_key?(:min_s)

     max_e = max_p = max_s = nil
     max_e = args[:max_e] if args.has_key?(:max_e)
     max_p = args[:max_p] if args.has_key?(:max_p)
     max_s = args[:max_s] if args.has_key?(:max_s)

     eccentricity      = min_e + (max_e.nil? ? rand : rand((max_e - min_e)*10000)/10000)
     speed             = min_s + (max_s.nil? ? rand : rand((max_s - min_s)*10000)/10000)
     semi_latus_rectum = min_p + (max_p.nil? ? rand : rand((max_p - min_p)))

     direction = args[:direction] || Motel::random_axis(:dimensions => dimensions)
     dmajx, dmajy, dmajz = *direction[0]
     dminx, dminy, dminz = *direction[1]

     Elliptical.new :relative_to => relative_to, :speed => speed,
                    :e => eccentricity, :p => semi_latus_rectum,
                    :dmajx => dmajx, :dmajy => dmajy, :dmajz => dmajz,
                    :dminx => dminx, :dminy => dminy, :dminz => dminz
   end
end

end # module MovementStrategies
end # module Motel
