# Motel Math Routines
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel
  # Return length of specified vector
  def self.length(x, y, z)
    Math.sqrt(x ** 2 + y ** 2 + z ** 2)
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
    raise ArgumentError, [l, x, y, z] if l <= 0
  
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
    projection = dot_product(x1, y1, z1, x2, y2, z2)
  
    # handle edge cases / out of domain errs
    projection = projection.round_to(0) unless (-1..1).include?(projection)
  
    Math.acos(projection)
  end
  
  # Retrieve the axis angle representation of the rotation
  # between the two specified vectors.
  #
  # Note this will return axis orthogonal to input vectors
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
  
    ax = if (a.abs <= CLOSE_ENOUGH || (a.abs - Math::PI).abs <= CLOSE_ENOUGH)
           # Special case, parallel vectors, pick arbitrary vector to generate axis
           na  = angle_between(x1, y1, z1, *CARTESIAN_NORMAL_VECTOR).abs
           vec = (na <= CLOSE_ENOUGH) || ((na - Math::PI).abs <= CLOSE_ENOUGH) ?
                  MAJOR_CARTESIAN_AXIS : CARTESIAN_NORMAL_VECTOR
           normal_vector(x1, y1, z1, *vec)
  
         else
           normal_vector(x1, y1, z1, x2, y2, z2)
         end
  
    ax = normalize(*ax)
    [a] + ax
  end
  
  # Rotate specified point by angle around specified axis angle
  #
  # Note this preserves original location's length
  # (multiple vectors may form same axis angle so this isn't
  #  necessarily congruent with axis_angle above)
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
  
  # Return angle which corresponds to specified coordinate when
  # rotated from original coordinate on specified axis.
  #
  # We utilize a bit of basic trig to calculate the angle of
  # rotation from the current position, original position, and axis
  # angle:
  #   - the angle we want is the single/unique apex angle in
  #     an isoscoles triangle residing on the surface of rotation
  #   - the angle we want can be computed with:
  #      sin(angle/2) = 1/2 base of triangle / length of side of triangle
  #   - the base of the triangle is simply the distance between the
  #     original & new coordinates
  #   - the side of the triangle can be retrieved by taking the sin of the
  #     angle between the axis vector and the original coordinate vector.
  #   - Finally we map the result to the domain of 0->2*PI
  def self.rotated_angle(x, y, z, ox, oy, oz, ax, ay, az)
    nlen = Motel.length( x,  y,  z)
    olen = Motel.length(ox, oy, oz)
    alen = Motel.length(ax, ay, az)
    raise ArgumentError if alen == 0 || nlen == 0 || olen == 0 ||
                           (nlen - olen).abs > CLOSE_ENOUGH
  
    # angle between rotation axis vector and coordinate vectors
    oa = angle_between(ox, oy, oz, ax, ay, az)
    na = angle_between( x,  y,  z, ax, ay, az)
    raise ArgumentError if (oa - na).abs > CLOSE_ENOUGH
    return 0 if oa < CLOSE_ENOUGH || (Math::PI - oa) < CLOSE_ENOUGH
  
    # length of side of rotation triangle
    ad = olen * Math.sin(oa)
  
    # base length of rotation triangle
    nd = Math.sqrt((x-ox)**2 + (y-oy)**2 + (z-oz)**2)
  
    # calc the rotation angle
    hsa = nd/ad/2
    hsa =  1 if hsa >  1 # compensate for rounding errors
    hsa = -1 if hsa < -1
    ra  = Math.asin(hsa)*2
  
    # determine if 'negative' rotation, adjust domain
    xp = cross_product(x,y,z,ox,oy,oz)
    ia = dot_product(*xp, ax,ay,az) > 0
    ia ? (2 * Math::PI - ra) : ra
  end
  
  # Return path of coordinates corresponding to the elliptical
  # path specified by the parameters
  #
  # @param [Integer,Float] p semi_latus_rectum of the elliptical path
  # @param [Integer,Float] e eccentricity of the elliptical path
  # @param [Array<Array<Float>,Array<Float>>] direction hash representing major/major axis' of path
  def self.elliptical_path(p, e, direction)
    path = []
  
    # direction
    majx = direction[0][0]
    majy = direction[0][1]
    majz = direction[0][2]
    minx = direction[1][0]
    miny = direction[1][1]
    minz = direction[1][2]
  
    # intercepts
    a = p / (1 - e**2)
    b = Math.sqrt(p * a)
  
    # linear eccentricity
    le = Math.sqrt(a**2 - b**2)
  
    # center (assumes location's movement_strategy.relative to is set to foci
    cx = -1 * majx * le
    cy = -1 * majy * le
    cz = -1 * majz * le
  
    # axis plane rotation
    nv1 = cross_product(majx,majy,majz,minx,miny,minz)
    ab1 = angle_between(0,0,1,nv1[0],nv1[1],nv1[2])
    ax1 = cross_product(0,0,1,nv1[0],nv1[1],nv1[2])
    ax1 = normalize(ax1[0],ax1[1],ax1[2])
  
    # axis rotation
    nmaj = rotate(1,0,0,ab1,ax1[0],ax1[1],ax1[2])
    ab2 = angle_between(nmaj[0],nmaj[1],nmaj[2],majx,majy,majz)
    ax2 = cross_product(nmaj[0],nmaj[1],nmaj[2],majx,majy,majz)
    ax2 = normalize(ax2[0],ax2[1],ax2[2])
  
    # path
    0.upto(2*Math::PI*100) { |i| i = i.to_f / 100 # 628 data points: 0,0.01,...,6.28
      x = a * Math.cos(i)
      y = b * Math.sin(i)
      n = [x,y,0]
      n = rotate(n[0], n[1], n[2], ab1, ax1[0], ax1[1], ax1[2])
      n = rotate(n[0], n[1], n[2], ab2, ax2[0], ax2[1], ax2[2])
      n[0] += cx; n[1] += cy; n[2] += cz;
  
      path.push(n);
    }
  
    return path
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
    return (x1 * x2 + y1 * y2 + z1 * z2).abs < CLOSE_ENOUGH
  end
end # module Motel
