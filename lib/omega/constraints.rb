# Mechanisms for loading constraints data
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'json'
require 'omega/common'

module Omega
  module Constraints
    def self.data_path
      @data_path ||= File.join(File.dirname(__FILE__), 'constraints.json')
    end

    def self.data
      @data ||= JSON.parse(File.read(data_path))
    end

    def self.coin_flip
      (rand * 2).floor == 0
    end

    def self.get(*target)
      current = data
      target.each { |t|
        current = current[t]
        return nil unless current
      }
      current
    end

    def self.deviation(*target)
      ntarget = Array.new(target)
      ntarget[ntarget.size-1] += 'Deviation'
      get *ntarget
    end

    def self.randomize(base, deviation)
      return base + rand * deviation * (coin_flip ? 1 : -1) if base.numeric?

      nx = coin_flip ? 1 : -1
      ny = coin_flip ? 1 : -1
      nz = coin_flip ? 1 : -1
      {'x' => base['x'] + rand * deviation['x'] * nx,
       'y' => base['y'] + rand * deviation['y'] * ny,
       'z' => base['z'] + rand * deviation['z'] * nz}
    end

    def self.rand_invert(value)
      return value * coin_flip ? 1 : -1 if value.numeric?

      nx = coin_flip ? 1 : -1
      ny = coin_flip ? 1 : -1
      nz = coin_flip ? 1 : -1
      {'x' => value['x'] * nx, 'y' => value['y'] * ny, 'z' => value['z'] * nz}
    end

    def self.gen(*target)
      base  = get *target
      deriv = deviation *target
      deriv ? randomize(base, deriv) : base
    end

    def self.max(*target)
      base  = get *target
      deriv = deviation *target
      return base unless deriv
      return base + deriv if base.numeric?
      {:x => base['x'] + deriv['x'],
       :y => base['y'] + deriv['y'],
       :z => base['z'] + deriv['z']}
    end

    def self.min(*target)
      base  = get *target
      deriv = deviation *target
      return base unless deriv
      return base - deriv if base.numeric?
      {:x => base['x'] - deriv['x'],
       :y => base['y'] - deriv['y'],
       :z => base['z'] - deriv['z']}
    end

    def self.valid?(value, *target)
      vmax = max(*target)
      vmin = min(*target)
      return value <= vmax && value >= vmin if value.numeric?
      value['x'] <= vmax['x'] && value['x'] >= vmin['x'] &&
      value['y'] <= vmax['y'] && value['y'] >= vmin['y'] &&
      value['z'] <= vmax['z'] && value['z'] >= vmin['z']
    end
  end # module Constraints
end # module Omega
