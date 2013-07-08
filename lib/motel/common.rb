# common & useful methods and other.
#
# Things that don't fit elsewhere
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# include logger dependencies
require 'logger'

module Motel

CLOSE_ENOUGH=0.0001
MAJOR_CARTESIAN_AXIS=[1,0,0]
MINOR_CARTESIAN_AXIS=[0,1,0]
CARTESIAN_NORMAL_VECTOR=[0,0,1]

# Generate and return a random id
def self.gen_uuid
  ["%02x"*4, "%02x"*2, "%02x"*2, "%02x"*2, "%02x"*6].join("-") %
      Array.new(16) {|x| rand(0xff) }
end

# Normalize and return specified vector
#
# @param [Integer,Float] x x component of vector
# @param [Integer,Float] y y component of vector
# @param [Integer,Float] z z component of vector
# @return [Array<Float,Float,Float>] array with the normalized x,y,z components
def self.normalize(x,y,z)
  return x,y,z if x.nil? || y.nil? || z.nil?

  l = Math.sqrt(x**2 + y**2 + z**2)
  raise ArgumentError if l <= 0

  x /= l
  y /= l
  z /= l
  return x,y,z
end

# Return boolean indicating if the specified vector is normalized
#
# @param [Integer,Float] x x component of vector
# @param [Integer,Float] y y component of vector
# @param [Integer,Float] z z component of vector
# @return [true,false] indicating if vector is normalized
def self.normalized?(x,y,z)
  return false if x.nil? || y.nil? || z.nil?
  l = Math.sqrt(x**2 + y**2 + z**2)
  l.to_f.round_to(1) == 1  # XXX not quite sure why to_f.round_to(1) is needed
end

# Return the cross product of the specified vectors
#
# @param [Integer,Float] x1 x component of first vector
# @param [Integer,Float] y1 y component of first vector
# @param [Integer,Float] z1 z component of first vector
# @param [Integer,Float] x2 x component of second vector
# @param [Integer,Float] y2 y component of second vector
# @param [Integer,Float] z2 z component of second vector
# @return [Array<Float>] array containing x,y,z coordinates of normal vector
def self.cross_product(x1, y1, z1, x2, y2, z2)
  x3 = y1 * z2 - z1 * y2
  y3 = z1 * x2 - x1 * z2
  z3 = x1 * y2 - y1 * x2
  [x3, y3, z3]
end
class << self; alias :normal_vector :cross_product ; end

# Return dot product of two vectors
#
# @param [Integer,Float] x1 x component of first vector
# @param [Integer,Float] y1 y component of first vector
# @param [Integer,Float] z1 z component of first vector
# @param [Integer,Float] x2 x component of second vector
# @param [Integer,Float] y2 y component of second vector
# @param [Integer,Float] z2 z component of second vector
# @return [Float] angle between specified vectors
def self.dot_product(x1, y1, z1, x2, y2, z2)
  x1 * x2 + y1 * y2 + z1 * z2
end

# Return the angle between vectors
#
# @param [Integer,Float] x1 x component of first vector
# @param [Integer,Float] y1 y component of first vector
# @param [Integer,Float] z1 z component of first vector
# @param [Integer,Float] x2 x component of second vector
# @param [Integer,Float] y2 y component of second vector
# @param [Integer,Float] z2 z component of second vector
# @return [Float] angle between specified vectors
def self.angle_between(x1, y1, z1, x2, y2, z2)
  x1, y1, z1 = normalize(x1, y1, z1)
  x2, y2, z2 = normalize(x2, y2, z2)
  d  = dot_product(x1, y1, z1, x2, y2, z2)
  a  = Math.acos(d)
  na = -1 * a

  x  = cross_product(x1, y1, z1, x2, y2, z2)
  d  = dot_product(*(x + CARTESIAN_NORMAL_VECTOR))
  d < 0 ? na : a
end

# Return matrix representing the rotation between vectors
#
# @param [Integer,Float] x1 x component of first vector
# @param [Integer,Float] y1 y component of first vector
# @param [Integer,Float] z1 z component of first vector
# @param [Integer,Float] x2 x component of second vector
# @param [Integer,Float] y2 y component of second vector
# @param [Integer,Float] z2 z component of second vector
#def self.rotation_between(x1, y1, z1, x2, y2, z2)
#  # convert axis angle between vectors to euler angles
#  # FIXME not working 100% right
#
#  rotation = []
#
#  # calc axis angle between vectors
#  x1, y1, z1 = normalize(x1, y1, z1)
#  x2, y2, z2 = normalize(x2, y2, z2)
#  angle = angle_between(x1, y1, z1, x2, y2, z2)
#  rot_axis = cross_product(x1, y1, z1, x2, y2, z2)
#  x,y,z = *rot_axis
#  s = Math.sin(angle) ; c = Math.cos(angle) ; t = 1 - c
#
#  # edge cases
#  if (x * y * t + z * s) > (1-CLOSE_ENOUGH)
#    rotation << 2 * Math.atan2(x * Math.sin(angle/2),Math.cos(angle/2))
#    rotation << Math::PI / 2
#    rotation << 0
#  elsif (x * y * t + z * s < (CLOSE_ENOUGH))
#    rotation << -2 * Math.atan2(x * Math.sin(angle/2),Math.cos(angle/2))
#    rotation << -Math::PI / 2
#    rotation << 0
#
#  # convert axis angle to euler rotation
#  else
#    rotation << Math.atan2(y * s - x * z * t, 1 - (y**2 + z**2) * t)
#    rotation << Math.asin(x * y * t + z * 2)
#    rotation << Math.atan2(x * s - y * z * t, 1 - (x**2 + z**2) * t)
#  end
#
#  rotation
#end

# Retrieve the axis angle representation of the rotation
# between the two specified vectors.
#
# @param [Integer,Float] x1 x component of first vector
# @param [Integer,Float] y1 y component of first vector
# @param [Integer,Float] z1 z component of first vector
# @param [Integer,Float] x2 x component of second vector
# @param [Integer,Float] y2 y component of second vector
# @param [Integer,Float] z2 z component of second vector
# @return [Array<Float>] array containing angle and x,y,z components of rotation axis
def self.axis_angle(x1, y1, z1, x2, y2, z2)
  a  = angle_between(x1, y1, z1, x2, y2, z2)
  ax = normal_vector(x1, y1, z1, x2, y2, z2)
  [a] + ax
end

# Rotate specified point by angle around specified axis angle
#
# @param [Integer,Float] x x component of location to rotate
# @param [Integer,Float] y y component of location to rotate
# @param [Integer,Float] z z component of location to rotate
# @param [Float] angle angle which to rotation location
# @param [Integer,Float] ax x component of rotation axis
# @param [Integer,Float] ay y component of rotation axis
# @param [Integer,Float] az z component of rotation axis
# @return [Array<Float>] x,y,z components of rotated location
def self.rotate(x, y, z, angle, ax, ay, az)
  # also support rotating x,y,z via specified euler rotation (each axis individually?)
  # use rodrigues rotation fomula
  # rotated = orig * cos(a) + (axis x orig) * sin(a) + axis(axis . orig)(1-cos(a))
  ax,ay,az = normalize(ax,ay,az)
  c = Math.cos(angle) ; s = Math.sin(angle)
  dot = dot_product(x, y, z, ax, ay, az)
  cross = cross_product(ax, ay, az, x, y, z)
  rx = x * c + cross[0] * s + ax * dot * (1-c)
  ry = y * c + cross[1] * s + ay * dot * (1-c)
  rz = z * c + cross[2] * s + az * dot * (1-c)
  [rx, ry, rz]
end

# Return boolean inidicating if two vectors are orthogonal
#
# @param [Integer,Float] x1 x component of first vector
# @param [Integer,Float] y1 y component of first vector
# @param [Integer,Float] z1 z component of first vector
# @param [Integer,Float] x2 x component of second vector
# @param [Integer,Float] y2 y component of second vector
# @param [Integer,Float] z2 z component of second vector
# @return [true,false] indicating if vectors are orthogonal
def self.orthogonal?(x1,y1,z1, x2,y2,z2)
  return false if x1.nil? || y1.nil? || z1.nil? || x2.nil? || y2.nil? || z2.nil?
  return (x1 * x2 + y1 * y2 + z1 * z2).abs < 0.00001 # TODO close enough?
end

# Covert coordinates to array of spherical coordinates in form of [theta,phi,distance]
#
# @param [Integer,Float] x x coordinate to convert
# @param [Integer,Float] y y coordinate to convert
# @param [Integer,Float] z z coordinate to convert
# @return [Array<Float>] array containing three elements, theta, phi, and distance
def self.to_spherical(x, y, z)
  return [] if x.nil? || y.nil? || z.nil?
  dist = Math.sqrt(x ** 2 + y ** 2 + z ** 2)
  phi   = Math.atan2(y, x)
  theta = dist == 0 ? 0 : Math.acos(z/dist)
  [theta, phi, dist]
end

# Convert spherical coordinates to an array of cartesian coordinates
#
# @param [Integer,Float] theta theta angle to convert
# @param [Integer,Float] phi phi angle to convert
# @param [Integer,Float] distance distance to convert
# @return [Array<Float>] array containing converted x,y,z coordinates
def self.from_spherical(theta, phi, dist)
    x = dist * Math.sin(theta) * Math.cos(phi);
    y = dist * Math.sin(theta) * Math.sin(phi);
    z = dist * Math.cos(theta);
    [x,y,z]
end

# Generate and return two orthogonal, normalized vectors
#
# @param [Hash] args hash of options to use when generating axis
# @option args [2,3] :dimensions number of dimensions to create axis for. Must be 2 or 3 (if 2, z-coordinate will always be 0)
# @return [Array<Array<Float,Float,Float>,Array<Float,Float,Float>>] array containing two arrays containing the x,y,z coordinates of the axis
def self.random_axis(args = {})
  dimensions  = args[:dimensions]  || 3
  raise ArgumentError if dimensions != 2 && dimensions != 3

  axis = []

  # generate random initial axis
  nx,ny,nz = (rand(2) == 0 ? 1 : -1), (rand(2) == 0 ? 1 : -1), (rand(2) == 0 ? 1 : -1)
  x1,y1,z1 = 0,0,0
  x1,y1,z1 =
     nx * rand(10), ny * rand(10), nz * rand(10) while x1 == 0 || y1 == 0 || z1 == 0
  z1 = 0 if dimensions == 2
  x1,y1,z1 = *Motel::normalize(x1, y1, z1)

  # generate two coordinates of the second,
  # calculate the final coordinate
  nx,ny,nz = (rand(2) == 0 ? 1 : -1), (rand(2) == 0 ? 1 : -1), (rand(2) == 0 ? 1 : -1)
  y2,z2 = 0,0
  y2,z2 = ny * rand(10), nz * rand(10) while y2 == 0 || z2 == 0
  z2 = 0 if dimensions == 2
  x2 = ((y1*y2 + z1*z2) * -1 / x1)
  x2,y2,z2 = *Motel::normalize(x2, y2, z2)

  return [[x1,y1,z1],[x2,y2,z2]]
end

end # module Motel

# We extend Float to provide floating point rounding mechanism
class Float

  # Round float to the specified precision
  #
  # @param [Integer] precision number of decimal places to return in float
  # @return float rounded to the specified precision
  def round_to(precision)
     return nil if precision <= 0
     return (self * 10 ** precision).round.to_f / (10 ** precision)
  end
end

# We extend Fixnum so we don't need to distinguish between an int and float
# to use round_to
class Fixnum
  # Returns self (fixnums are always rounded)
  def round_to(precision)
    return self
  end
end
