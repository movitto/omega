# The Location model definition
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'motel/models/movement_strategy'

module Motel
module Models

# A Location defines an optional parent location and the x,y,z
# cartesian  coordinates of the location relative to that parent.
# If parent is not specified x,y,z are ignored and this location
# is assumed to be the 'center' of the system to which it belongs
# Also is related to a movable object defining the parameters
# of the locations movement 
class Location < ActiveRecord::Base
   # a location may have a parent and/or act as a parent to others
   belongs_to :location,  :foreign_key => :parent_id
   has_many   :locations, :foreign_key => :parent_id, :dependent => :destroy

   belongs_to :movement_strategy

   alias :parent    :location
   alias :parent=   :location=
   alias :children  :locations
   alias :children=  :locations=

   # default to the stopped movement strategy if not set on validation
   before_validation :default_movement_strategy
   def default_movement_strategy
      self.movement_strategy = MovementStrategy.stopped if movement_strategy.nil?
   end

   public
   validates_presence_of :movement_strategy

   validates_presence_of [:x, :y, :z],
   :unless => Proc.new { |location| location.location.nil? }

   validates_presence_of :location,
   :unless => Proc.new { |location| location.x.nil? &&
                                    location.y.nil? &&
                                    location.z.nil? }

   public

   # return non-nil attributes in hash
   def to_h
     result = {}
     #result[:id] = id unless id.nil?
     result[:parent_id] = parent_id unless parent_id.nil?
     result[:x] = x unless x.nil?
     result[:y] = y unless y.nil?
     result[:z] = z unless z.nil?
     return result
   end

   # convert location to a string
   def to_s
     "id:#{id}; parent_id:#{parent_id}; parent: #{parent.nil? ? "nil" : "notnil"}; x:#{x}; y#{y}; z#{z}; " +
     "movement_strategy:#{movement_strategy.to_s}; children:#{locations.join(",")}"
   end

   # return sum of the x values of this location and all its parents,
   # eg the absolute 'x' of the location
   def total_x
     return 0 if location.nil?
     return location.total_x + x
   end

   # return sum of the y values of this location and all its parents
   # eg the absolute 'y' of the location
   def total_y
     return 0 if location.nil?
     return location.total_y + y
   end

   # return sum of the z values of this location and all its parents
   # eg the absolute 'z' of the location
   def total_z
     return 0 if location.nil?
     return location.total_z + z
   end
end

end # module Models
end # module Motel
