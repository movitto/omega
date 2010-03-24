# The Location entity
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/movement_strategy'

module Motel

# A Location defines an optional parent location and the x,y,z
# cartesian  coordinates of the location relative to that parent.
# If parent is not specified x,y,z are ignored and this location
# is assumed to be the 'center' of the system to which it belongs
# Also is related to a movable object defining the parameters
# of the locations movement 
class Location

   # id of location and parent, and coordinates relative to that parent
   attr_accessor :id, :x, :y, :z, :parent_id

   # handle to parent location and array of children
   attr_accessor :parent, :children

   # movement strategy which location move in accordance to
   attr_accessor :movement_strategy

   # array of callbacks to be invoked on movement
   attr_accessor :movement_callbacks

   # TODO proximity callbacks, association between foreign location id,
   # proximity distance (radius of sphere around location) and callable
   # handler to be invoked when locations are within proximity

   # a generic association which this location can belong to
   attr_accessor :entity

   def initialize(args = {})
      # default to the stopped movement strategy
      @movement_strategy = MovementStrategies::Stopped.instance
      @movement_callbacks = []
      @children = []

      @id = args[:id] if args.has_key? :id
      @parent_id = args[:parent_id] if args.has_key? :parent_id
      @x = args[:x] if args.has_key? :x
      @y = args[:y] if args.has_key? :y
      @z = args[:z] if args.has_key? :z
      @parent = args[:parent] if args.has_key? :parent
      @parent.children.push self unless @parent.nil? || @parent.children.include?(self)
      @movement_strategy = args[:movement_strategy] if args.has_key? :movement_strategy

      @x = 0 if @x.nil?
      @y = 0 if @y.nil?
      @z = 0 if @z.nil?
   end

   # update this location's attributes to match other's set attributes
   def update(location)
      @x = location.x unless location.x.nil?
      @y = location.y unless location.y.nil?
      @z = location.z unless location.z.nil?
      @movement_strategy = location.movement_strategy unless location.movement_strategy.nil?
      @parent = location.parent unless location.parent.nil?
      @parent_id = location.parent_id unless location.parent_id.nil?
   end

   # return this location's root location
   def root
     return self if parent.nil?
     return parent.root
   end

   # traverse all chilren recursively, calling block for each
   def traverse_descendants(&bl)
      children.each { |child|
         bl.call child
         child.traverse_descendants &bl
      }
   end

   # return sum of the x values of this location and all its parents,
   # eg the absolute 'x' of the location
   def total_x
     return 0 if parent.nil?
     return parent.total_x + x
   end

   # return sum of the y values of this location and all its parents
   # eg the absolute 'y' of the location
   def total_y
     return 0 if parent.nil?
     return parent.total_y + y
   end

   # return sum of the z values of this location and all its parents
   # eg the absolute 'z' of the location
   def total_z
     return 0 if parent.nil?
     return parent.total_z + z
   end

end

end # module Motel
