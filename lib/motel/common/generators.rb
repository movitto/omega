# Motel Generators
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel
  # Generate and return a random id
  def self.gen_uuid
    ["%02x"*4, "%02x"*2, "%02x"*2, "%02x"*2, "%02x"*6].join("-") %
        Array.new(16) {|x| rand(0xff) }
  end

  # Generate and reutrn a random normalized vector
  def self.rand_vector
    nx,ny,nz = (rand(2) == 0 ? 1 : -1), (rand(2) == 0 ? 1 : -1), (rand(2) == 0 ? 1 : -1)
    x1,y1,z1 = nx * rand(10), ny * rand(10), nz * rand(10)
    z1 = nz * rand(10) until z1 != 0 if x1 == 0 && y1 == 0 && z1 == 0
    x1,y1,z1 = *Motel::normalize(x1, y1, z1)
    [x1,y1,z1]
  end
  
  # Generate and return two orthogonal, normalized vectors
  #
  # @param [Hash] args hash of options to use when generating axis
  # @option args [2,3] :dimensions number of dimensions to create axis for. Must be 2 or 3 (if 2, z-coordinate will always be 0)
  # @option args [Array<Float>] :orthogonal_to if pass in, axis orthogonal to the specified vector will be returned
  # @return [Array<Array<Float,Float,Float>,Array<Float,Float,Float>>] array containing two arrays containing the x,y,z coordinates of the axis
  def self.random_axis(args = {})
    dimensions  = args[:dimensions] || 3
    raise ArgumentError if dimensions != 2 && dimensions != 3
  
    # generate random orthogonal vector if not specified
    orthogonal = args[:orthogonal_to]
    unless orthogonal
      orthogonal = [rand,rand,rand]
      orthogonal = Motel::normalize(*orthogonal)
    end
  
    # generate random tmp vector
    tx,ty,tz = rand, rand, rand
    tx,ty,tz = *Motel::normalize(tx,ty,tz)
  
    # generate first axis vector
    x1,y1,z1 = *Motel.cross_product(tx,ty,tz,*orthogonal)
    x1,y1,z1 = *Motel::normalize(x1,y1,z1)
  
    # rotate first axis vector by 1.57 around orthogonal to get other
    x2,y2,z2 = *Motel.rotate(x1,y1,z1,Math::PI/2,*orthogonal)
    x2,y2,z2 = *Motel.normalize(x2,y2,z2)
  
    # 0 out z if 2D
    z1 = z2 = 0 if dimensions == 2
  
    return [[x1,y1,z1],[x2,y2,z2]]
  end
end # module Motel
