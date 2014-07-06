# The Elliptcial MovementStrategy Generators Mixin
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel
module MovementStrategies
module EllipticalGenerators
  def random_coordinates
    coordinates_from_theta(Math.random * 2 * Math::PI)
  end

  module ClassMethods
    # Generate and return a random elliptical movement strategy
    def random(args = {})
      dimensions  = args[:dimensions]  || 3
      relative_to = args[:relative_to] || Elliptical::CENTER

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
  end # module ClassMethods

  def self.included(base)
    base.extend(ClassMethods)
  end
end # module EllipticalGenerators
end # module MovementStrategies
end # module Motel
