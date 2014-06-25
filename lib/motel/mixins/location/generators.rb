# Motel Generators Mixin.
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel

# Mixed into Location, provides generators for common locations
module Generators

  module ClassMethods
    # Create a minimal valid location with id
    def basic(id)
      Location.new :coordinates => [0,0,0], :orientation => [0,0,1], :id => id
    end

    # Create a random location and return it.
    # @param [Hash] args optional hash of args containing limits to the randomization
    def random(args = {})
      max_x = max_y = max_z = nil
      max_x = max_y = max_z = args[:max] if args.has_key?(:max)
      max_x = args[:max_x] if args.has_key?(:max_x)
      max_y = args[:max_y] if args.has_key?(:max_y)
      max_z = args[:max_z] if args.has_key?(:max_z)

      min_x = min_y = min_z = 0
      min_x = min_y = min_z = args[:min] if args.has_key?(:min)
      min_x = args[:min_x] if args.has_key?(:min_x)
      min_y = args[:min_y] if args.has_key?(:min_y)
      min_z = args[:min_z] if args.has_key?(:min_z)

      # TODO this is a little weird w/ the semantics of the 'min'
      # arguments, at some point look into changing this
      nx = rand(2) == 0 ? -1 : 1
      ny = rand(2) == 0 ? -1 : 1
      nz = rand(2) == 0 ? -1 : 1

      new_x = ((min_x.nil? ? 0 : min_x) + (max_x.nil? ? rand : rand(max_x - min_x))) * nx
      new_y = ((min_y.nil? ? 0 : min_y) + (max_y.nil? ? rand : rand(max_y - min_y))) * ny
      new_z = ((min_z.nil? ? 0 : min_z) + (max_z.nil? ? rand : rand(max_z - min_z))) * nz
      new_args = {:coordinates => [new_x,new_y,new_z], :orientation => [0,0,1]}.merge args

      loc = Location.new new_args
      return loc
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end # module Generators
end # module Motel
