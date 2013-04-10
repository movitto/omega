# The Elliptcial MovementStrategy model definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/movement_strategy'

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
   # [RELATIVE_TO_CENTER, RELATIVE_TO_FOCI] value indicates if the parent
   #   of the location tracked by this strategy is at the center or the foci
   #   of the ellipse.
   #
   # Affects how elliptical path is calculated
   attr_accessor :relative_to

   # Distance the location moves per second
   attr_accessor :speed

   # Describes the elliptical path through which the location moves
   attr_accessor :eccentricity, :semi_latus_rectum

   # Direction vector corresponding to the major axis of the elliptical path
   attr_accessor :direction_major_x, :direction_major_y, :direction_major_z

   # Direction vector corresponding to the minor axis of the elliptical path
   attr_accessor :direction_minor_x, :direction_minor_y, :direction_minor_z

   # Motel::MovementStrategies::Elliptical initializer
   #
   # Direction vectors will be normalized if not already
   #
   # @param [Hash] args hash of options to initialize the elliptical movement strategy with
   # @option args [Array<Array<Float,Float,Float>,Array<Float,Float,Float>>] :direction array containing two arrays containing x,y,z coords of major/minor direction vectors
   # @option args [Float] :direction_major array containing x,y,z coords of major direction vector
   # @option args [Float] :direction_minor array containing x,y,z coords of minor direction vector
   # @option args [Float] :direction_major_x x coordinate of major direction vector
   # @option args [Float] :direction_major_y y coordinate of major direction vector
   # @option args [Float] :direction_major_z z coordinate of major direction vector
   # @option args [Float] :direction_minor_x x coordinate of minor direction vector
   # @option args [Float] :direction_minor_y y coordinate of minor direction vector
   # @option args [Float] :direction_minor_z z coordinate of minor direction vector
   # @option args [Float] :speed speed to assign to movement strategy
   # @option args [RELATIVE_TO_CENTER, RELATIVE_TO_FOCI] :relative_to how the parent location is related to this elliptical path
   # @option args [Float] :eccentricity,:e eccentricity to assign to elliptical path
   # @option args [Float] :semi_latus_rectum,:p semi latus rectum to assign to elliptical path
   # @raise [Motel::InvalidMovementStrategy] if movement strategy is not valid (see {#valid?})
   def initialize(args = {})
     @relative_to        = args[:relative_to]       || args['relative_to']       || RELATIVE_TO_FOCI
     @speed              = args[:speed]             || args['speed']
     @eccentricity       = args[:eccentricity]      || args['eccentricity']      || args['e']           || args[:e]
     @semi_latus_rectum  = args[:semi_latus_rectum] || args['semi_latus_rectum'] || args['p']           || args[:p]

     if args.has_key?('direction')
       @direction_major_x, @direction_major_y, @direction_major_z = *args['direction'][0]
       @direction_minor_x, @direction_minor_y, @direction_minor_z = *args['direction'][1]
     end

     if args.has_key?(:direction)
       @direction_major_x, @direction_major_y, @direction_major_z = *args[:direction][0]
       @direction_minor_x, @direction_minor_y, @direction_minor_z = *args[:direction][1]
     end

     if args.has_key?('direction_major')
       @direction_major_x, @direction_major_y, @direction_major_z = *args['direction_major']
     end

     if args.has_key?(:direction_major)
       @direction_major_x, @direction_major_y, @direction_major_z = *args[:direction_major]
     end

     if args.has_key?('direction_minor')
       @direction_minor_x, @direction_minor_y, @direction_minor_z = *args['direction_minor']
     end

     if args.has_key?(:direction_minor)
       @direction_minor_x, @direction_minor_y, @direction_minor_z = *args[:direction_minor]
     end

     @direction_major_x   = args['direction_major_x'] if args.has_key? 'direction_major_x'
     @direction_major_y   = args['direction_major_y'] if args.has_key? 'direction_major_y'
     @direction_major_z   = args['direction_major_z'] if args.has_key? 'direction_major_z'

     @direction_major_x   = args[:direction_major_x] if args.has_key? :direction_major_x
     @direction_major_y   = args[:direction_major_y] if args.has_key? :direction_major_y
     @direction_major_z   = args[:direction_major_z] if args.has_key? :direction_major_z

     @direction_minor_x   = args['direction_minor_x'] if args.has_key? 'direction_minor_x'
     @direction_minor_y   = args['direction_minor_y'] if args.has_key? 'direction_minor_y'
     @direction_minor_z   = args['direction_minor_z'] if args.has_key? 'direction_minor_z'

     @direction_minor_x   = args[:direction_minor_x] if args.has_key? :direction_minor_x
     @direction_minor_y   = args[:direction_minor_y] if args.has_key? :direction_minor_y
     @direction_minor_z   = args[:direction_minor_z] if args.has_key? :direction_minor_z

     @direction_major_x   = 1 if @direction_major_x.nil?
     @direction_major_y   = 0 if @direction_major_y.nil?
     @direction_major_z   = 0 if @direction_major_z.nil?
     @direction_minor_x   = 0 if @direction_minor_x.nil?
     @direction_minor_y   = 1 if @direction_minor_y.nil?
     @direction_minor_z   = 0 if @direction_minor_z.nil?
     super(args)

     @direction_major_x, @direction_major_y, @direction_major_z = 
         Motel::normalize(@direction_major_x, @direction_major_y, @direction_major_z)

     @direction_minor_x, @direction_minor_y, @direction_minor_z = 
        Motel::normalize(@direction_minor_x, @direction_minor_y, @direction_minor_z)

     raise InvalidMovementStrategy.new("elliptical movement strategy not valid") unless valid?
   end

   # Return boolean indicating if this movement strategy is valid
   #
   # Tests the various attributes of the elliptical movement strategy, returning 'true'
   # if everything is consistent, else false.
   #
   # Currently tests
   # * direction vectors are normalized
   # * direction vectors are orthogonal
   # * eccentricity is a valid float/fixnum > 0
   # * semi latus rectum is a valid float/fixnum > 0
   # * speed is a valid float/fixnum > 0
   # * relative_to is RELATIVE_TO_CENTER or RELATIVE_TO_FOCI
   def valid?
     Motel::normalized?(@direction_major_x, @direction_major_y, @direction_major_z) &&
     Motel::normalized?(@direction_minor_x, @direction_minor_y, @direction_minor_z) &&
     Motel::orthogonal?(@direction_major_x, @direction_major_y, @direction_major_z, @direction_minor_x, @direction_minor_y, @direction_minor_z) &&
     [Float, Fixnum].include?(@eccentricity.class) && @eccentricity >= 0 && @eccentricity <= 1 &&
     [Float, Fixnum].include?(@semi_latus_rectum.class) && @semi_latus_rectum > 0 &&
     [Float, Fixnum].include?(@speed.class) && @speed > 0 &&
     [RELATIVE_TO_CENTER, RELATIVE_TO_FOCI].include?(@relative_to)
   end

   # Return the eccentricity of the elliptical path
   def e
     self.eccentricity
   end

   # Set the eccentricity of the elliptical path
   def e=(v)
    self.eccentricity= v
   end

   # Return the semi latus rectum of the elliptical path
   def p
     self.semi_latus_rectum
   end

   # Set the semi latus rectum of the elliptical path
   def p=(v)
     self.semi_latus_rectum = v
   end

   # Indicates that parent location is at center of elliptical path
   RELATIVE_TO_CENTER = "center"

   # Indicates that parent location is at one of the focis of the elliptical path
   RELATIVE_TO_FOCI   = "foci"

   # Implementation of {Motel::MovementStrategy#move}
   def move(location, elapsed_seconds)
     # make sure this movement strategy is valid
     unless valid?
        RJR::Logger.warn "elliptical movement strategy not valid, not proceeding with move"
        return
     end

     # make sure location is on ellipse
     unless location_valid? location
        cx,cy,cz = closest_coordinates location
        RJR::Logger.warn "location #{location} not on ellipse, adjusting to closest location #{cx},#{cy},#{cz} before moving"
        location.x,location.y,location.z = cx,cy,cz
     end

     RJR::Logger.debug "moving location #{location.id} via elliptical movement strategy"

     # calculate distance moved and update x,y,z accordingly
     distance = speed * elapsed_seconds

     nX,nY,nZ = coordinates_from_theta(theta(location) + distance)
     location.x = nX
     location.y = nY
     location.z = nZ
   end

   # Convert movement strategy to json representation and return it
   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay   => step_delay,
                         :speed        => speed,
                         :relative_to  => relative_to,
                         :eccentricity => eccentricity,
                         :semi_latus_rectum => semi_latus_rectum,
                         :direction_major_x => direction_major_x,
                         :direction_major_y => direction_major_y,
                         :direction_major_z => direction_major_z,
                         :direction_minor_x => direction_minor_x,
                         :direction_minor_y => direction_minor_y,
                         :direction_minor_z => direction_minor_z }
     }.to_json(*a)
   end

   # Convert movement strategy to human readable string and return it
   def to_s
     # TODO flush out
     "elliptical-()"
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
      return 0,0,0 if relative_to == RELATIVE_TO_CENTER

      a,b = intercepts
      le  = linear_eccentricity

      centerX = -1 * direction_major_x * le; 
      centerY = -1 * direction_major_y * le; 
      centerZ = -1 * direction_major_z * le;
      return centerX, centerY, centerZ
    end

    # return the coordinates of a focus position
    # F = direction_major * le
    def focus
      return 0,0,0 if relative_to == RELATIVE_TO_FOCI

      a,b = intercepts
      le  = linear_eccentricity

      focusX = direction_major_x * le; 
      focusY = direction_major_y * le; 
      focusZ = direction_major_z * le;
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
      a,b = intercepts
      ocX,ocY,ocZ = origin_centered_coordinates location

      t = (direction_minor_y * ocX - direction_minor_x * ocY) /
           (a * (direction_minor_y * direction_major_x - direction_minor_x * direction_major_y))
      t= 1.0  if(t>1.0) 
      t= -1.0 if(t<-1.0)
      theta = Math.acos(t)

      # determine if current point is in negative quadrants of min axis coordinate system
      below = ocY < ((direction_minor_x * ocX + direction_minor_z * ocZ) / (-direction_minor_y)) 

      # adjust to compenate for acos loss if necessary
      theta = (3 * Math::PI / 2) + (Math::PI / 2 - theta) if (below) 

      return theta;
    end

    # calculate the x,y,z coordinates of a location on the elliptical
    # path given its theta
    #
    # Elliptical path equation:
    # [x,y,z] = a * cos(theta) * maj + b * sin(theta) * min 
    #   (if centered at origin)
    def coordinates_from_theta(theta)
       a,b      = intercepts
       cX,cY,cZ = center

       x = cX + a * Math.cos(theta) * direction_major_x + b * Math.sin(theta) * direction_minor_x
       y = cY + a * Math.cos(theta) * direction_major_y + b * Math.sin(theta) * direction_minor_y
       z = cZ + a * Math.cos(theta) * direction_major_z + b * Math.sin(theta) * direction_minor_z

       # round to two decimal places
       x = x.round_to(2)
       y = y.round_to(2)
       z = z.round_to(2)

       return x,y,z
    end

   # return x,y,z coordinates of the closest point on the ellipse to the given location
   def closest_coordinates(location)
      t = theta location

      return nil if t.nan?

      return coordinates_from_theta(t)
   end

   # return boolean indicating if the given location is on the ellipse or not
   def location_valid?(location)
      x,y,z = closest_coordinates(location)

      return (x - location.x).round_to(4) == 0 &&
             (y - location.y).round_to(4) == 0 &&
             (z - location.z).round_to(4) == 0
   end

   # Generate and return a random elliptical movement strategy
   def self.random(args = {})
     dimensions  = args[:dimensions]  || 3
     relative_to = args[:relative_to] || RELATIVE_TO_CENTER

     min_e = min_l = min_s = 0
     min_e = args[:min_e] if args.has_key?(:min_e)
     min_l = args[:min_l] if args.has_key?(:min_l)
     min_s = args[:min_s] if args.has_key?(:min_s)

     max_e = max_l = max_s = nil
     max_e = args[:max_e] if args.has_key?(:max_e)
     max_l = args[:max_l] if args.has_key?(:max_l)
     max_s = args[:max_s] if args.has_key?(:max_s)

     # multiply by 10000 to ensure floats < 1 for e + speed
     eccentricity      = max_e.nil? ? rand : ((min_e*10000 + rand(max_e*10000 - min_e*10000))/10000)
     speed             = max_s.nil? ? rand : ((min_s*10000 + rand(max_s*10000 - min_s*10000))/10000)
     semi_latus_rectum = max_l.nil? ? rand : (min_l + rand(max_l - min_l))

     axis = Motel::random_axis :dimensions => dimensions
     direction_major_x, direction_major_y, direction_major_z = *axis[0]
     direction_minor_x, direction_minor_y, direction_minor_z = *axis[1]

     strategy = Elliptical.new :relative_to => relative_to,
                               :eccentricity => eccentricity,
                               :semi_latus_rectum => semi_latus_rectum,
                               :speed => speed,
                               :direction_major_x => direction_major_x,
                               :direction_major_y => direction_major_y,
                               :direction_major_z => direction_major_z,
                               :direction_minor_x => direction_minor_x,
                               :direction_minor_y => direction_minor_y,
                               :direction_minor_z => direction_minor_z

     return strategy
   end

end

end # module MovementStrategies
end # module Motel
