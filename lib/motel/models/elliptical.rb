# The Elliptcial MovementStrategy model definition
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'motel/common'
require 'motel/models/movement_strategy'

module Motel
module Models

# The Elliptical MovementStrategy moves a location
# on an elliptical path described by major/minor 
# axis direction vectors, and an eccentricity /
# semi_latus_rectum. The path equation will 
# also depend on the value of the relative_to
# field indicating if the parent location 
# is the center or a foci of the ellipse.
# Lastly a speed value is required indicating the
# angular velocity of the location.
class Elliptical < MovementStrategy

   # Elliptical MovementStrategy must specify x,y,z components of 
   # the major and minor axis direction vectors
   validates_presence_of [:direction_major_x, 
                          :direction_major_y, 
                          :direction_major_z,
                          :direction_minor_x, 
                          :direction_minor_y, 
                          :direction_minor_z]

   # make sure the unit direction vectors are normal
   before_validation :normalize_direction_vectors
   def normalize_direction_vectors
      dx, dy, dz =
         normalize(direction_major_x, direction_major_y, direction_major_z)
      self.direction_major_x, self.direction_major_y, self.direction_major_z = dx, dy, dz

      dx, dy, dz =
         normalize(direction_minor_x, direction_minor_y, direction_minor_z)
      self.direction_minor_x, self.direction_minor_y, self.direction_minor_z = dx, dy, dz
   end


   # Elliptical MovementStrategy must specify the angular velocity
   # at which the location is moving
   validates_presence_of      :speed
   validates_numericality_of  :speed,
      :greater_than_or_equal_to => 0,
      :less_than_or_equal_to    => 2 * Math::PI

   # the eccentricity of the ellipse
   validates_presence_of     :eccentricity
   validates_numericality_of :eccentricity,
      :greater_than_or_equal_to => 0,
      :less_than_or_equal_to    => 1

   def e
     eccentricity
   end
   def e=(v)
    eccentricity= v
   end

   # the semi_latus_rectum of the ellipse
   validates_presence_of :semi_latus_rectum
   validates_numericality_of :semi_latus_rectum,
      :greater_than_or_equal_to => 0

   def p
     semi_latus_rectum
   end
   def p=(v)
     semi_latus_rectum = v
   end

   # the possible relative_to values
   RELATIVE_TO_CENTER = "center"
   RELATIVE_TO_FOCI   = "foci"

   # must be relative to a parent center or foci
   validates_presence_of :relative_to
   validates_inclusion_of :relative_to,
     :in => [ RELATIVE_TO_CENTER, RELATIVE_TO_FOCI ]

   # ActiveRecord::Base::validate
   def validate
      errors.add("direction vectors must be orthogonal") unless orthogonal?(direction_major_x, direction_major_y, direction_major_z,
                                                                            direction_minor_x, direction_minor_y, direction_minor_z)
   end

   # convert non-nil elliptical movement strategy attributes to a hash
   def to_h
     result = {}
     result[:speed] = speed unless speed.nil?
     result[:eccentricity] = eccentricity unless eccentricity.nil?
     result[:semi_latus_rectum] = semi_latus_rectum unless semi_latus_rectum.nil?
     result[:relative_to] = relative_to unless relative_to.nil?
     result[:direction_major_x] = direction_major_x unless direction_major_x.nil?
     result[:direction_major_y] = direction_major_y unless direction_major_y.nil?
     result[:direction_major_z] = direction_major_z unless direction_major_z.nil?
     result[:direction_minor_x] = direction_minor_x unless direction_minor_x.nil?
     result[:direction_minor_y] = direction_minor_y unless direction_minor_y.nil?
     result[:direction_minor_z] = direction_minor_z unless direction_minor_z.nil?
     return result
   end

   # convert elliptical movement strategy to a string
   def to_s
     super + "; speed:#{speed}; eccentricity:#{eccentricity}; semi_latus_rectum:#{semi_latus_rectum}; relative_to:#{relative_to}; " + 
               "direction_major_x:#{direction_major_x}; direction_major_y:#{direction_major_y}; direction_major_z:#{direction_major_z}; " +
               "direction_minor_x:#{direction_minor_x}; direction_minor_y:#{direction_minor_y}; direction_minor_z:#{direction_minor_z}"
   end

   # Motel::Models::MovementStrategy::move
   def move(location, elapsed_seconds)
      # make sure this movement strategy is valid
      unless valid?
         Logger.warn "elliptical movement strategy not valid, not proceeding with move"
         return
      end

      # make sure location is on ellipse
      unless location_valid? location
         cx,cy,cz = closest_coordinates location
         Logger.warn "location #{location} not on ellipse, the closest location is #{cl}, not proceeding with move"
         return
      end

     Logger.debug "moving location #{location} via elliptical movement strategy"

     # calculate distance moved and update x,y,z accordingly
     distance = speed * elapsed_seconds

     nX,nY,nZ = coordinates_from_theta(theta(location) + distance)
     location.x = nX
     location.y = nY
     location.z = nZ

     Logger.debug "moved location #{location} via elliptical movement strategy"
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
      t= 1.0 if(t>1.0) 
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

end

end # module Models
end # module Motel
