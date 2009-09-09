# common & useful methods and other.
#
# Things that don't fit elsewhere
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

module Motel

# generate a random id
def gen_uuid
  ["%02x"*4, "%02x"*2, "%02x"*2, "%02x"*2, "%02x"*6].join("-") %
      Array.new(16) {|x| rand(0xff) }
end

# normalize a vector if not normal already, 
# eg divide each component x,y,z by the 
# vector length and return them
def normalize(x,y,z)
  return x,y,z if x.nil? || y.nil? || z.nil?

  l = Math.sqrt(x**2 + y**2 + z**2)
  if l != 1
    x /= l
    y /= l
    z /= l
  end
  return x,y,z
end

# determine if two vectors are orthogonal
def orthogonal?(x1,y1,z1, x2,y2,z2)
  return false if x1.nil? || y1.nil? || z1.nil? || x2.nil? || y2.nil? || z2.nil?
  return (x1 * x2 + y1 * y2 + z1 * z2).abs == 0
end

end # module Motel

# provide floating point rounding mechanism
class Float
  def round_to(precision)
     return nil if precision <= 0
     return (self * 10 ** precision).round.to_f / (10 ** precision)
  end
end

# try to find key equal to method, returning value if found
#class Hash  
#  def method_missing(method, *params)  
#    method = method.to_sym  
#    return self[method] if self.keys.collect{ |k| k.to_sym }.include?(method)  
#    super  
#  end  
#end
